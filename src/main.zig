const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const c = @cImport({
    @cDefine("GUI_WINDOW_FILE_DIALOG_IMPLEMENTATION", {});
    @cInclude("gui_window_file_dialog.h");
});

const Texture = rl.Texture;

pub fn main() !void {
    const screen_width = 1280;
    const screen_height = 800;

    rl.initWindow(screen_width, screen_height, "Test");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var file_dialog_state = c.InitGuiWindowFileDialog(c.GetWorkingDirectory());
    var file_name_to_load: [3300:0]u8 = undefined;
    var texture: Texture = undefined;

    @memset(&file_name_to_load, 0);

    while (!rl.windowShouldClose()) {
        if (file_dialog_state.SelectFilePressed) {
            const null_terminated_fileNameText = file_dialog_state.fileNameText[0 .. file_dialog_state.fileNameText.len - 1 :0];
            if (rl.isFileExtension(null_terminated_fileNameText.ptr, ".png")) {
                const path_dir = std.mem.span(file_dialog_state.dirPathText[0 .. file_dialog_state.dirPathText.len - 1 :0].ptr);
                std.debug.print("{s}{s}{s}\n", .{ path_dir, c.PATH_SEPERATOR, file_dialog_state.fileNameText });
                @memset(&file_name_to_load, 0);
                // @memcpy(&file_name_to_load, rl.textFormat("%s/%s", .{ &file_dialog_state.dirPathText, &file_dialog_state.fileNameText }));
                _ = try std.fmt.bufPrint(&file_name_to_load, "{s}{s}{s}", .{ path_dir, c.PATH_SEPERATOR, file_dialog_state.fileNameText });
                std.debug.print("{s}\n", .{file_name_to_load});
                rl.unloadTexture(texture);
                texture = rl.loadTexture(&file_name_to_load);
            }

            file_dialog_state.SelectFilePressed = false;
        }

        if (rl.isFileDropped()) {
            const dropped_files = rl.loadDroppedFiles();
            std.debug.print("files dropped", .{});
            for (0..dropped_files.count) |index| {
                std.debug.print("Path: {s}", .{dropped_files.paths[index]});
            }
            rl.unloadDroppedFiles(dropped_files);
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.dark_blue);

        rl.drawTexture(texture, screen_width / 2 - @divTrunc(texture.width, 2), screen_height / 2 - @divTrunc(texture.height, 2) - 5, rl.Color.white);
        // rl.drawText("start!", 190, 200, 20, rl.Color.light_gray);

        // const span_file_name = std.mem.span(file_name_to_load[0..file_name_to_load.len :0].ptr);
        // _ = span_file_name;
        rl.drawText(&file_name_to_load, 208, screen_height - 20, 10, rl.Color.gray);

        if (file_dialog_state.windowActive) rg.guiLock();

        if (rg.guiButton(rl.Rectangle.init(20, 20, 140, 30), rg.guiIconText(@intFromEnum(rg.GuiIconName.icon_file_open), "open image")) != 0) file_dialog_state.windowActive = true;

        rg.guiUnlock();

        c.GuiWindowFileDialog(&file_dialog_state);
    }
}
