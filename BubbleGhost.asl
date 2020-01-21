state("emuhawk") {}


startup {
    refreshRate = 0.5;

    vars.basicSplits = new byte[] {6, 11, 14, 27, 35};
    for(int w = 1; w < 36; w++) {
        settings.Add("l"+w, true, "Level " + w);
    }

    vars.SigScan = (Func<Process, SigScanTarget, IntPtr>)((proc, target) => {
        print("[Autosplitter] Scanning memory");
        IntPtr ptr = IntPtr.Zero;
        foreach (var page in proc.MemoryPages()) {
            var scanner = new SignatureScanner(proc, page.BaseAddress, (int)page.RegionSize);
            if ((ptr = scanner.Scan(target)) != IntPtr.Zero)
                break;
        }
        return ptr;
    });

    vars.InitVars = (Action)(() => {
        // vars.animCount = 0;
        // vars.diedInBoss = false;
    });

    vars.timerResetVars = (EventHandler)((s, e) => {
        vars.InitVars();
    });

    print("yooooo");
    // timer.OnStart += vars.timerResetVars;
}

init {
    IntPtr ptr = IntPtr.Zero;
    bool useDeepPtr = false;
    print(memory.ProcessName);
    if (memory.ProcessName.Equals("emuhawk", StringComparison.OrdinalIgnoreCase)) {
        var target = new SigScanTarget(0, "05 00 00 00 ?? 00 00 00 00 ?? ?? 00 00 ?? ?? 00 00 ?? ?? 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? F8 00 00 00");
        IntPtr wram = vars.SigScan(game, target);
        if (wram != IntPtr.Zero)
            ptr = (IntPtr)((long)(wram-0x40)-(long)modules.First().BaseAddress);
        useDeepPtr = true;
    } else {
        var target = new SigScanTarget(0, "00 00 00 ?? FF 00 ?? ?? ?? ?? 00 00 00 00 00 01 00 00 00 00 ?? ?? ?? ?? ?? 01");
        ptr = vars.SigScan(game, target);
    }
    if (ptr == IntPtr.Zero)
        throw new Exception("[Autosplitter] Can't find signature");

    vars.watchers = new MemoryWatcherList() {
        // (vars.anim = useDeepPtr ? new MemoryWatcher<byte>(new DeepPointer((int)ptr, 0x6)) : new MemoryWatcher<byte>(ptr-0x1033)),
        // (vars.world = useDeepPtr ? new MemoryWatcher<byte>(new DeepPointer((int)ptr, 0x103B)) : new MemoryWatcher<byte>(ptr+0x2)),
        // (vars.room = useDeepPtr ? new MemoryWatcher<byte>(new DeepPointer((int)ptr, 0x103E)) : new MemoryWatcher<byte>(ptr+0x5)),
        // (vars.life = useDeepPtr ? new MemoryWatcher<byte>(new DeepPointer((int)ptr, 0x1089)) : new MemoryWatcher<byte>(ptr+0x50)),
        (vars.health = useDeepPtr ? new MemoryWatcher<byte>(new DeepPointer((int)ptr, 0xAF)) : new MemoryWatcher<byte>(ptr+0x5A)),
        // (vars.star = useDeepPtr ? new MemoryWatcher<byte>(new DeepPointer((int)ptr, 0x13DE)) : new MemoryWatcher<byte>(ptr+0x3A5))
    };

    vars.InitVars();

    refreshRate = 200/3d;
}

update { //updates vars on each update loop
    vars.watchers.UpdateAll(game);
    print("coucou");
}

start { // true if you want to start
    return vars.health.Changed;
}

split { // true if you want to split

}

reset { // true uf you want to reset
    // return vars.life.Changed && vars.life.Current == 0;
}

shutdown {
    print("coucou");
    return false;
    // timer.OnStart -= vars.timerResetVars;
}
