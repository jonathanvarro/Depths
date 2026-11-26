"""Rebuild the #302 design sections. These are proposals, never live maps."""
import json
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/damp-caves-layout-sections.json"


class Section:
    def __init__(self, ident, title, width, height):
        self.ident, self.title = ident, title
        self.grid = [["#"] * width for _ in range(height)]
        self.rooms, self.points, self.exits, self.patrol = [], [], [], []

    def room(self, x, y, width=5, height=5):
        self.rooms.append([x, y, width, height])
        for row in range(y, y + height):
            for col in range(x, x + width):
                self.grid[row][col] = ","

    def path(self, *points):
        for (x, y), (end_x, end_y) in zip(points, points[1:]):
            assert x == end_x or y == end_y, "axis-aligned grid paths"
            while (x, y) != (end_x, end_y):
                if self.grid[y][x] == "#":
                    self.grid[y][x] = "."
                x += (end_x > x) - (end_x < x)
                y += (end_y > y) - (end_y < y)
            if self.grid[y][x] == "#":
                self.grid[y][x] = "."

    def mark(self, x, y, char):
        assert self.grid[y][x] != "#", (self.ident, x, y)
        self.grid[y][x] = char

    def point(self, name, x, y, role):
        assert self.grid[y][x] != "#", name
        self.points.append({"name": name, "cell": [x, y], "role": role})

    def exit(self, x, y, destination):
        self.mark(x, y, ">")
        self.exits.append({"cell": [x, y], "destination": destination})

    def pack(self):
        return {"id": self.ident, "title": self.title,
                "rows": ["".join(row) for row in self.grid], "rooms": self.rooms,
                "points": self.points, "exits": self.exits, "patrol": self.patrol}


def build():
    sections = []
    a = Section("junction", "Two exits beyond the drowned drift", 25, 19)
    for room in [(2, 2, 5, 4), (10, 5, 5, 5), (18, 2, 5, 4), (18, 12, 5, 4), (2, 12, 5, 3)]:
        a.room(*room)
    a.path((4, 3), (8, 3), (8, 7), (12, 7))
    a.path((12, 7), (12, 3), (20, 3))
    a.path((13, 8), (16, 8), (16, 14), (20, 14))
    a.path((10, 8), (8, 8), (8, 13), (4, 13))
    for x, y in [(10, 6), (11, 6), (12, 6), (13, 6), (14, 6), (13, 7)]:
        a.mark(x, y, "~")
    a.mark(4, 3, "<"); a.mark(12, 8, "E"); a.mark(4, 13, "C")
    a.exit(20, 3, "Cavern"); a.exit(20, 14, "Fungal Hollows")
    a.point("Drowned drift", 8, 3, "Rails/debris at the transition from mining to wet natural rock; no flood rule implied")
    a.point("Two destination clues", 12, 7, "Worked goblin marks toward Cavern; dense fungal traces only near the Hollows exit")
    a.point("Shallow newt encounter", 12, 8, "Newt pair can emerge before combat begins; no hidden guaranteed first strike")
    a.point("Ambient newt", 13, 6, "Small noncombat crossing between puddles, off the exit cells")
    a.point("Optional cache", 4, 13, "A dead end with a reward rather than a required key")
    sections.append(a.pack())

    a = Section("sump", "Dry ledge around the sump", 25, 19)
    for room in [(2, 2, 5, 4), (10, 3, 5, 5), (18, 12, 5, 4), (2, 12, 5, 4)]:
        a.room(*room)
    a.path((4, 3), (12, 3))
    a.path((14, 7), (16, 7), (16, 14), (20, 14))
    a.path((10, 7), (8, 7), (8, 14), (4, 14))
    for y in range(4, 7):
        for x in range(11, 14):
            a.mark(x, y, "w")
    a.mark(4, 3, "<"); a.mark(14, 5, "E"); a.mark(4, 14, "E")
    a.exit(20, 14, "Section continuation (not an extra world exit)")
    a.point("The sump", 12, 5, "3x3 deep visual basin, surrounded by a dry walkable rim")
    a.point("Newts surface", 14, 5, "Fight trigger on the dry rim, visible gills and wake before engagement")
    a.point("Blind crawler nook", 4, 14, "One crawler with a rat in a narrow optional dead end; retain retreat access")
    a.point("Wall leeches", 10, 5, "Clinging at a wet boundary, with a dry route around the pool; no collision")
    sections.append(a.pack())

    a = Section("mother-patrol", "A water-linked patrol loop beside the dry route", 35, 27)
    for room in [(1, 1, 5, 4), (1, 22, 5, 4), (11, 5, 5, 5), (27, 5, 5, 5), (27, 19, 5, 5), (11, 19, 5, 5)]:
        a.room(*room)
    a.path((3, 2), (3, 24)); a.path((3, 13), (13, 13))
    a.path((13, 7), (29, 7), (29, 21), (13, 21), (13, 7))
    for x in range(13, 30):
        a.mark(x, 7, "~"); a.mark(x, 21, "~")
    for y in range(7, 22):
        a.mark(29, y, "~"); a.mark(13, y, "~")
    a.mark(3, 2, "<"); a.exit(3, 24, "Section continuation (not an extra world exit)")
    a.mark(29, 21, "E")
    a.patrol = [[13, 7], [29, 7], [29, 21], [13, 21], [13, 7]]
    a.point("Drowned Mother resting room", 29, 21, "Leader start; at least 12 walking steps from both stair anchors")
    a.point("First possible cold glow", 11, 13, "At the side-loop threshold; actual visibility remains caller-owned")
    a.point("Dry main bypass", 3, 13, "The leader does not patrol the only route between stairs")
    a.point("Leech shallows", 28, 7, "Shallow approach suitable for a leech/newt fight; no guaranteed swarm gate")
    sections.append(a.pack())

    a = Section("quest-lair", "Weeping wall, protected moss site and optional brood", 31, 25)
    for room in [(2, 2, 5, 5), (12, 2, 5, 5), (24, 2, 5, 5), (2, 16, 5, 5), (12, 16, 5, 5), (24, 16, 5, 5), (12, 9, 5, 5)]:
        a.room(*room)
    a.path((4, 4), (26, 4)); a.path((8, 4), (8, 18), (26, 18))
    a.path((4, 18), (14, 18)); a.path((8, 11), (14, 11))
    a.mark(4, 4, "<"); a.mark(14, 3, "O"); a.mark(26, 4, "O")
    a.mark(4, 18, "C"); a.mark(14, 18, "R"); a.mark(26, 18, "E"); a.mark(20, 4, "D")
    a.mark(14, 11, "O"); a.exit(15, 19, "Section continuation (not an extra world exit)")
    for x in range(12, 17): a.mark(x, 12, "~")
    a.point("The weeping wall", 14, 3, "Flowstone landmark; drip anchors belong against the wall")
    a.point("Bitter-moss package reserve", 26, 4, "Reserve actual 5x4 healing_moss package footprint plus connection margin; O denotes its intended event, not a package implementation")
    a.point("Wet lost cache", 4, 18, "Rotted crates; persistent buried-cache state remains with the existing event")
    a.point("Bone silt", 4, 16, "Loose bones collected in a dark silt bank at an optional end")
    a.point("Rimstone stair", 14, 11, "Small terraced pools, with a dry edge to the optional object")
    a.point("Brood warning threshold", 22, 18, "Existing Go in/Back away before committing; no required exit or quest target behind it")
    a.point("Brood fight", 26, 18, "Retain the existing lair contract; no new monster or boss rules assigned")
    sections.append(a.pack())
    return {"issue": 302, "status": "Design reference only; no live generator or water/encounter change",
            "legend": "# rock; , room; . corridor; E C T O R < > D B existing roles; ~ proposed shallow visual wetness; w proposed deep basin requiring review",
            "coordinates": "zero-based x,y; > may be a section connector unless explicitly destination-tagged",
            "sections": sections}


def distances(rows, start, exclude_deep=False):
    result = {tuple(start): 0}; todo = deque([tuple(start)])
    while todo:
        x, y = todo.popleft()
        for p in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]:
            col, row = p
            if 0 <= row < len(rows) and 0 <= col < len(rows[0]) and p not in result:
                if rows[row][col] not in ("#B" + ("w" if exclude_deep else "")):
                    result[p] = result[(x, y)] + 1; todo.append(p)
    return result


def validate(data):
    checks = 0
    for section in data["sections"]:
        rows = section["rows"]; width = len(rows[0])
        assert width <= 35 and len(rows) <= 35
        assert all(len(row) == width for row in rows)
        assert all(c in "#, .ECTOR<>DB~w" for row in rows for c in row)
        checks += 3
        start = next((x, y) for y, row in enumerate(rows) for x, c in enumerate(row) if c == "<")
        reached = distances(rows, start); dry = distances(rows, start, True)
        walkable = {(x, y) for y, row in enumerate(rows) for x, c in enumerate(row) if c not in "#B"}
        assert set(reached) == walkable, section["id"] + " detached floor cells"
        assert all(max(room[2:]) <= 5 for room in section["rooms"])
        checks += 2
        for exit in section["exits"]:
            assert tuple(exit["cell"]) in dry, section["id"] + " forces deep wading"
            checks += 1
        for point in section["points"]:
            assert tuple(point["cell"]) in reached, point["name"]
            checks += 1
        if section["id"] == "junction":
            assert {e["destination"] for e in section["exits"]} == {"Cavern", "Fungal Hollows"}
            checks += 1
        if section["id"] == "mother-patrol":
            patrol = section["patrol"]
            assert patrol[0] == patrol[-1]
            assert all(tuple(cell) in reached for cell in patrol)
            leader = next(p["cell"] for p in section["points"] if "resting room" in p["name"])
            anchors = [start, tuple(section["exits"][0]["cell"])]
            assert all(distances(rows, anchor)[tuple(leader)] >= 12 for anchor in anchors)
            # Named-pack rejection or a blocked side entrance cannot cut the main bypass.
            blocked = [list(row) for row in rows]; blocked[13][9] = "B"
            assert anchors[1] in distances(["".join(r) for r in blocked], anchors[0])
            checks += 4
    return checks


if __name__ == "__main__":
    data = build(); checks = validate(data)
    OUT.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(f"DAMP_LAYOUT checks={checks} failures=0 sections={len(data['sections'])}")
