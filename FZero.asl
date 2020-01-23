// Autosplitter for Fzero that splits on each race's end or each lap's end
// according to the user's will
// Is compatible with UltimeDecathlon8's pack's version of snes9x


state("snes9x") {}
state("snes9x-x64") {}
state("bsnes") {}
state("higan") {}
state("emuhawk") {}

startup
{
    settings.Add("s0", true, "Split on each race's end");
    settings.Add("s1", false, "Split on each lap's end (overrides above if checked)");
}

init
{
    var states = new Dictionary<int, long>
    {
        { 9646080, 0x97EE04 },      // Snes9x-rr 1.60
        { 13565952, 0x140925118 },  // Snes9x-rr 1.60 (x64)
        { 9027584, 0x94DB54 },      // Snes9x 1.60
        { 12836864, 0x1408D8BE8 },  // Snes9x 1.60 (x64)
        { 16019456, 0x94D144 },     // higan v106
        { 15360000, 0x8AB144 },     // higan v106.112
        { 10096640, 0x72BECC },     // bsnes v107
        { 10338304, 0x762F2C },     // bsnes v107.1
        { 47230976, 0x765F2C },     // bsnes v107.2/107.3
        { 131543040, 0xA9BD5C },    // bsnes v110
        { 51924992, 0xA9DD5C },     // bsnes v111
        { 52056064, 0xAAED7C },     // bsnes v112
        { 7061504, 0x36F11500240 }, // BizHawk 2.3
        { 7249920, 0x36F11500240 }, // BizHawk 2.3.1
        { 6938624, 0x36F11500240 }, // BizHawk 2.3.2
        { 0x697000, 0x14040DF18}, // snes9x-1.53-x64 #UltimeDecathlon8
    };

    long memoryOffset;
    if (states.TryGetValue(modules.First().ModuleMemorySize, out memoryOffset))
        if (memory.ProcessName.ToLower().Contains("snes9x"))
            memoryOffset = memory.ReadValue<int>((IntPtr)memoryOffset);
    if (memoryOffset == 0)
        throw new Exception("Memory not yet initialized.");
    vars.watchers = new MemoryWatcherList
    {
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x55) { Name = "SelectionMenu" },
        new MemoryWatcher<int>((IntPtr)memoryOffset + 0x10E0) { Name = "Position" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0xD40) { Name = "CurrentLap" },
    };
}

update
{
    vars.watchers.UpdateAll(game);
}

start
{
    return vars.watchers["SelectionMenu"].Old == 6 && vars.watchers["SelectionMenu"].Current == 7;
}

reset
{
    return vars.watchers["CurrentLap"].Old != 0 && vars.watchers["CurrentLap"].Old != 255 && vars.watchers["CurrentLap"].Current == 0;
}

split
{
    if (settings["s1"]) {
        return vars.watchers["CurrentLap"].Old != 255 && (vars.watchers["CurrentLap"].Current - vars.watchers["CurrentLap"].Old) == 1;
    }
    return vars.watchers["CurrentLap"].Old == 4 && vars.watchers["CurrentLap"].Current == 5;
}
