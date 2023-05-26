const std = @import("std");
const rc = @import("main.zig");
const expect = std.testing.expect;

threadlocal var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "basic" {
    {
        var five = try rc.Rc(i32).init(gpa.allocator(), 5);
        defer five.release();

        five.value.* += 1;
        try expect(five.value.* == 6);

        try expect(five.strongCount() == 1);
        try expect(five.weakCount() == 0);

        var next_five = five.retain();
        try expect(next_five.strongCount() == 2);
        try expect(five.weakCount() == 0);
        next_five.release();

        try expect(five.strongCount() == 1);
        try expect(five.weakCount() == 0);
    }

    _ = gpa.detectLeaks();
}

test "basic atomics" {
    {
        var five = try rc.Arc(i32).init(gpa.allocator(), 5);
        defer five.release();

        five.value.* += 1;
        try expect(five.value.* == 6);

        try expect(five.strongCount() == 1);
        try expect(five.weakCount() == 0);

        var next_five = five.retain();
        try expect(next_five.strongCount() == 2);
        try expect(five.weakCount() == 0);
        next_five.release();

        try expect(five.strongCount() == 1);
        try expect(five.weakCount() == 0);
    }

    try expect(!gpa.detectLeaks());
}

test "cyclic" {
    const Gadget = struct {
        _me: Weak,

        const Self = @This();
        const Rc = rc.Rc(Self);
        const Weak = rc.Weak(Self);

        pub fn init(alloc: std.mem.Allocator) !Rc {
            return Rc.initCyclic(alloc, Self.data_fn);
        }

        pub fn me(self: *Self) Rc {
            return self._me.upgrade().?;
        }

        pub fn deinit(self: Self) void {
            self._me.release();
        }

        fn data_fn(m: *Weak) Self {
            return Self{ ._me = m.retain() };
        }
    };

    {
        var gadget = try Gadget.init(gpa.allocator());
        defer gadget.releaseWithFn(Gadget.deinit);

        try expect(gadget.strongCount() == 1);
        try expect(gadget.weakCount() == 1);
    }

    // try expect(!gpa.detectLeaks());
}
