const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const c = @cImport({
    @cInclude("amber/style_amber.h");
    @cDefine("GUI_WINDOW_FILE_DIALOG_IMPLEMENTATION", {});
    @cInclude("gui_window_file_dialog.h");
});

const Texture = rl.Texture;
const Rectangle = rl.Rectangle;

pub fn main() !void {
    const screen_width = 1280;
    const screen_height = 800;

    rl.initWindow(screen_width, screen_height, "CVApp");
    defer rl.closeWindow();

    rl.setTargetFPS(60);
    c.GuiLoadStyleAmber();

    var file_dialog_state = c.InitGuiWindowFileDialog(c.GetWorkingDirectory());
    var file_name_to_load: [3300:0]u8 = undefined;
    var texture: Texture = undefined;

    @memset(&file_name_to_load, 0);

    // init rectangles
    const gui_panel_1 = Rectangle.init(0, 0, screen_width, 40);
    const image_load_button = Rectangle.init(10, 8, 24, 24);

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
            std.debug.print("files dropped\n", .{});
            for (0..dropped_files.count) |index| {
                std.debug.print("Path: {s}\n", .{dropped_files.paths[index]});
            }

            rl.unloadTexture(texture);
            texture = rl.loadTexture(dropped_files.paths[0]);
            rl.unloadDroppedFiles(dropped_files);
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        const background_color: i32 = @intFromEnum(rg.GuiDefaultProperty.background_color);
        rl.clearBackground(rl.getColor(@intCast(rg.guiGetStyle(.default, background_color))));

        rl.gl.rlPushMatrix();
        rl.gl.rlTranslatef(0, 25 * 50, 0);
        rl.gl.rlRotatef(90, 1, 0, 0);
        rl.drawGrid(100, 30);
        rl.gl.rlPopMatrix();

        _ = rg.guiPanel(gui_panel_1, null);

        rl.drawTexture(texture, screen_width / 2 - @divTrunc(texture.width, 2), screen_height / 2 - @divTrunc(texture.height, 2) - 5, rl.Color.white);
        if (file_dialog_state.windowActive) rg.guiLock();

        if (rg.guiButton(image_load_button, rg.guiIconText(@intFromEnum(rg.GuiIconName.icon_file_open), "")) != 0) file_dialog_state.windowActive = true;

        rg.guiUnlock();

        c.GuiWindowFileDialog(&file_dialog_state);
    }
}
