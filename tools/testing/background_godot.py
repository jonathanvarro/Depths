"""Run a Windows GPU check on a private, non-interactive desktop.

Never calls SwitchDesktop or touches existing windows. A failure exits; it
does not fall back to showing the test on the owner's interactive desktop.
"""
import argparse
import ctypes as C
from ctypes import wintypes as W
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import uuid


def run():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--timeout', type=float, default=180)
    parser.add_argument('arguments', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if os.name != 'nt':
        parser.error('This launcher requires Windows; use headless checks elsewhere.')
    godot, project, output = args.godot.resolve(), args.project.resolve(), args.output.resolve()
    if not godot.is_file() or not (project / 'project.godot').is_file():
        parser.error('The Godot executable and project.godot must exist.')
    if args.timeout <= 0:
        parser.error('Timeout must be positive.')
    extra = args.arguments[1:] if args.arguments[:1] == ['--'] else args.arguments
    engine_args = extra[:extra.index('--')] if '--' in extra else extra
    if any(x in engine_args for x in ['--fullscreen', '-f', '--editor', '-e', '--path', '--always-on-top', '-t']):
        parser.error('Use a direct windowed check; editor, fullscreen, path overrides and topmost are not allowed.')
    output.mkdir(parents=True, exist_ok=True)

    class STARTUPINFO(C.Structure):
        _fields_ = [('cb', W.DWORD), ('lpReserved', W.LPWSTR), ('lpDesktop', W.LPWSTR),
                    ('lpTitle', W.LPWSTR), ('dwX', W.DWORD), ('dwY', W.DWORD),
                    ('dwXSize', W.DWORD), ('dwYSize', W.DWORD), ('dwXCountChars', W.DWORD),
                    ('dwYCountChars', W.DWORD), ('dwFillAttribute', W.DWORD),
                    ('dwFlags', W.DWORD), ('wShowWindow', W.WORD), ('cbReserved2', W.WORD),
                    ('lpReserved2', C.POINTER(W.BYTE)), ('hStdInput', W.HANDLE),
                    ('hStdOutput', W.HANDLE), ('hStdError', W.HANDLE)]

    class PROCESS_INFORMATION(C.Structure):
        _fields_ = [('hProcess', W.HANDLE), ('hThread', W.HANDLE),
                    ('dwProcessId', W.DWORD), ('dwThreadId', W.DWORD)]

    user = C.WinDLL('user32', use_last_error=True)
    kernel = C.WinDLL('kernel32', use_last_error=True)
    user.CreateDesktopW.argtypes = [W.LPCWSTR, W.LPCWSTR, C.c_void_p, W.DWORD, W.DWORD, C.c_void_p]
    user.CreateDesktopW.restype = W.HANDLE
    user.CloseDesktop.argtypes = [W.HANDLE]
    user.CloseDesktop.restype = W.BOOL
    user.GetForegroundWindow.restype = W.HWND
    user.GetWindowThreadProcessId.argtypes = [W.HWND, C.POINTER(W.DWORD)]
    kernel.CreateProcessW.argtypes = [W.LPCWSTR, W.LPWSTR, C.c_void_p, C.c_void_p,
                                    W.BOOL, W.DWORD, C.c_void_p, W.LPCWSTR,
                                    C.POINTER(STARTUPINFO), C.POINTER(PROCESS_INFORMATION)]
    kernel.CreateProcessW.restype = W.BOOL
    kernel.WaitForSingleObject.argtypes = [W.HANDLE, W.DWORD]
    kernel.WaitForSingleObject.restype = W.DWORD
    kernel.GetExitCodeProcess.argtypes = [W.HANDLE, C.POINTER(W.DWORD)]
    kernel.TerminateProcess.argtypes = [W.HANDLE, W.UINT]
    kernel.CloseHandle.argtypes = [W.HANDLE]
    # A job holds Godot and anything it starts (the console build launches
    # the real game as a child), so a timeout stops them all and the
    # foreground check covers the game window too (#253, 2026-11-11).
    kernel.CreateJobObjectW.argtypes = [C.c_void_p, W.LPCWSTR]
    kernel.CreateJobObjectW.restype = W.HANDLE
    kernel.SetInformationJobObject.argtypes = [W.HANDLE, C.c_int, C.c_void_p, W.DWORD]
    kernel.AssignProcessToJobObject.argtypes = [W.HANDLE, W.HANDLE]
    kernel.TerminateJobObject.argtypes = [W.HANDLE, W.UINT]
    kernel.ResumeThread.argtypes = [W.HANDLE]
    kernel.OpenProcess.argtypes = [W.DWORD, W.BOOL, W.DWORD]
    kernel.OpenProcess.restype = W.HANDLE
    kernel.IsProcessInJob.argtypes = [W.HANDLE, W.HANDLE, C.POINTER(W.BOOL)]

    class LIMITS(C.Structure):
        _fields_ = [('PerProcessUserTimeLimit', C.c_int64), ('PerJobUserTimeLimit', C.c_int64),
                    ('LimitFlags', W.DWORD), ('MinimumWorkingSetSize', C.c_size_t),
                    ('MaximumWorkingSetSize', C.c_size_t), ('ActiveProcessLimit', W.DWORD),
                    ('Affinity', C.c_size_t), ('PriorityClass', W.DWORD), ('SchedulingClass', W.DWORD)]

    class EXTENDED(C.Structure):
        _fields_ = [('Basic', LIMITS), ('Io', C.c_uint64 * 6), ('ProcessMemoryLimit', C.c_size_t),
                    ('JobMemoryLimit', C.c_size_t), ('PeakProcessMemoryUsed', C.c_size_t),
                    ('PeakJobMemoryUsed', C.c_size_t)]

    job = kernel.CreateJobObjectW(None, None)
    if not job:
        raise C.WinError(C.get_last_error())
    limits = EXTENDED()
    limits.Basic.LimitFlags = 0x2000  # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
    if not kernel.SetInformationJobObject(job, 9, C.byref(limits), C.sizeof(limits)):
        raise C.WinError(C.get_last_error())

    def in_job(pid: int) -> bool:
        handle = kernel.OpenProcess(0x1000, False, pid)  # PROCESS_QUERY_LIMITED_INFORMATION
        if not handle:
            return False
        inside = W.BOOL()
        kernel.IsProcessInJob(handle, job, C.byref(inside))
        kernel.CloseHandle(handle)
        return bool(inside.value)

    # READOBJECTS | CREATEWINDOW | CREATEMENU | ENUMERATE | WRITEOBJECTS.
    # Deliberately omit DESKTOP_SWITCHDESKTOP; this desktop is never displayed.
    desktop_name = 'DepthsCheck_' + uuid.uuid4().hex
    desktop = user.CreateDesktopW(desktop_name, None, None, 0, 0xC7, None)
    if not desktop:
        raise C.WinError(C.get_last_error())
    before = user.GetForegroundWindow()
    process = PROCESS_INFORMATION()
    sampled_foreground = False
    timed_out = False
    import msvcrt
    try:
        with open(os.devnull, 'rb') as stdin, (output/'stdout.log').open('wb') as stdout, (output/'stderr.log').open('wb') as stderr:
            handles = [msvcrt.get_osfhandle(f.fileno()) for f in [stdin, stdout, stderr]]
            for handle in handles:
                os.set_handle_inheritable(handle, True)
            startup = STARTUPINFO()
            startup.cb = C.sizeof(startup)
            startup.lpDesktop = desktop_name
            startup.dwFlags = 0x100 | 0x1  # STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW
            startup.wShowWindow = 0        # SW_HIDE for the helper console.
            startup.hStdInput, startup.hStdOutput, startup.hStdError = handles
            command = C.create_unicode_buffer(subprocess.list2cmdline([str(godot), '--path', str(project), '--windowed', *extra]))
            try:
                ok = kernel.CreateProcessW(str(godot), command, None, None, True,
                                           0x08000000 | 0x4, None, str(project), C.byref(startup), C.byref(process))  # + CREATE_SUSPENDED
                if not ok:
                    raise C.WinError(C.get_last_error())
                if not kernel.AssignProcessToJobObject(job, process.hProcess):
                    kernel.TerminateProcess(process.hProcess, 1)
                    raise C.WinError(C.get_last_error())
                kernel.ResumeThread(process.hThread)
            finally:
                for handle in handles:
                    os.set_handle_inheritable(handle, False)
            started = time.monotonic()
            while True:
                owner = W.DWORD()
                user.GetWindowThreadProcessId(user.GetForegroundWindow(), C.byref(owner))
                sampled_foreground |= owner.value == process.dwProcessId or (owner.value != 0 and in_job(owner.value))
                result = kernel.WaitForSingleObject(process.hProcess, 50)
                if result == 0:
                    break
                if result == 0xFFFFFFFF:
                    raise C.WinError(C.get_last_error())
                if time.monotonic() - started > args.timeout:
                    timed_out = True
                    kernel.TerminateJobObject(job, 124)
                    kernel.WaitForSingleObject(process.hProcess, 5000)
                    break
            exit_code = W.DWORD()
            if not kernel.GetExitCodeProcess(process.hProcess, C.byref(exit_code)):
                raise C.WinError(C.get_last_error())
        report = {'private_desktop': desktop_name, 'exit_code': exit_code.value,
                  'timed_out': timed_out, 'test_was_foreground': sampled_foreground,
                  'foreground_unchanged': before == user.GetForegroundWindow(),
                  'elapsed_seconds': round(time.monotonic()-started, 3)}
        (output/'launch.json').write_text(json.dumps(report, indent=2)+'\n')
        print(json.dumps(report))
        return exit_code.value if not sampled_foreground else 1
    finally:
        if process.hProcess:
            remaining = W.DWORD()
            if kernel.GetExitCodeProcess(process.hProcess, C.byref(remaining)) and remaining.value == 259:
                kernel.TerminateProcess(process.hProcess, 124)
                kernel.WaitForSingleObject(process.hProcess, 5000)
        kernel.TerminateJobObject(job, 124)  # anything Godot left running
        kernel.CloseHandle(job)
        if process.hThread:
            kernel.CloseHandle(process.hThread)
        if process.hProcess:
            kernel.CloseHandle(process.hProcess)
        if not user.CloseDesktop(desktop):
            print('Private desktop cleanup failed: '+str(C.WinError(C.get_last_error())), file=sys.stderr)


if __name__ == '__main__':
    sys.exit(run())
