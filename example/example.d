module example;

//~ import std.exception;
//~ import std.stdio;

//~ import std.algorithm;
import std.exception;
import std.file;
//~ import std.functional;
import std.path;
import std.stdio;
import std.string;

import deimos.glfw.glfw3;

import glad.gl.enums;
import glad.gl.ext;
import glad.gl.funcs;
import glad.gl.loader;
import glad.gl.types;

import glwtf.input;
import glwtf.window;

import imgui;

import window;

// imgui states
bool  checkState1  = false;
bool  checkState2  = false;
bool  collapseState  = true;
bool  checked4  = false;
float value1    = 50.0;
float value2    = 30.0;
int scrollarea1 = 0;
int scrollarea2 = 0;
int scrollarea3 = 0;
int mscroll = 0;
char[] lastClickInfo;  // last clicked element information
char[1024] buffer;  // buffer to hold our text
int windowWidth, windowHeight;

/**
    This tells OpenGL what area of the available area we are
    rendering to. In this case, we change it to match the
    full available area. Without this function call resizing
    the window would have no effect on the rendering.
*/
void onWindowResize(int width, int height)
{
    // bottom-left position.
    enum int x = 0;
    enum int y = 0;

    /**
        This function defines the current viewport transform.
        It defines as a region of the window, specified by the
        bottom-left position and a width/height.

        Note about the viewport transform:
        It is the process of transforming vertex data from normalized
        device coordinate space to window space. It specifies the
        viewable region of a window.
    */
    glViewport(x, y, width, height);

    windowWidth = width;
    windowHeight = height;
}

int main(string[] args)
{
    int width = 1024, height = 768;

    auto window = createWindow("imgui", WindowMode.windowed, width, height);

    auto onScroll = delegate void (double hOffset, double vOffset)
    {
        mscroll = -cast(int)vOffset;
    };

    window.on_scroll.strongConnect(onScroll);

    // trigger initial viewport transform.
    onWindowResize(width, height);

    window.on_resize.strongConnect(toDelegate(&onWindowResize));

    // Enable vertical sync (on cards that support it)
    glfwSwapInterval(1);

    string fontPath = thisExePath().dirName().buildPath("../").buildPath("DroidSans.ttf");

    enforce(imguiInit(fontPath));

    glClearColor(0.8f, 0.8f, 0.8f, 1.0f);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_DEPTH_TEST);

    while (!glfwWindowShouldClose(window.window))
    {
        renderGui(window);

        /* Swap front and back buffers. */
        window.swap_buffers();

        /* Poll for and process events. */
        glfwPollEvents();

        if (window.is_key_down(GLFW_KEY_ESCAPE))
            glfwSetWindowShouldClose(window.window, true);
    }

    // Clean UI
    imguiDestroy();

    return 0;
}

void renderGui(Window window)
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Mouse states
    ubyte mousebutton = 0;
    double mouseX;
    double mouseY;
    glfwGetCursorPos(window.window, &mouseX, &mouseY);

    const scrollAreaWidth = windowWidth / 4;
    const scrollAreaHeight = windowHeight - 20;

    int mousex = cast(int)mouseX;
    int mousey = cast(int)mouseY;

    mousey = windowHeight - mousey;
    int leftButton   = glfwGetMouseButton(window.window, GLFW_MOUSE_BUTTON_LEFT);
    int rightButton  = glfwGetMouseButton(window.window, GLFW_MOUSE_BUTTON_RIGHT);
    int middleButton = glfwGetMouseButton(window.window, GLFW_MOUSE_BUTTON_MIDDLE);

    if (leftButton == GLFW_PRESS)
        mousebutton |= MouseButton.left;

    imguiBeginFrame(mousex, mousey, mousebutton, mscroll);

    if (mscroll != 0)
        mscroll = 0;

    imguiBeginScrollArea("Scroll area 1", 10, 10, scrollAreaWidth, scrollAreaHeight, &scrollarea1);

    imguiSeparatorLine();
    imguiSeparator();

    imguiButton("Button");

    imguiButton("Disabled button", Enabled.no);
    imguiItem("Item");
    imguiItem("Disabled item", Enabled.no);

    if (imguiCheck("Checkbox", &checkState1))
        lastClickInfo = sformat(buffer, "Toggled the checkbox to: '%s'", checkState1 ? "On" : "Off");

    // should not be clickable
    enforce(!imguiCheck("Disabled checkbox", &checkState2, Enabled.no));

    if (imguiCollapse("Collapse", "subtext", &collapseState))
        lastClickInfo = sformat(buffer, "subtext changed to: '%s'", collapseState ? "Maximized" : "Minimized");

    if (collapseState)
    {
        imguiIndent();
        imguiLabel("Collapsable element");
        imguiUnindent();
    }

    // should not be clickable
    enforce(!imguiCollapse("Disabled collapse", "subtext", &checked4, Enabled.no));

    imguiLabel("Label");
    imguiValue("Value");
    imguiSlider("Slider", &value1, 0.0, 100.0, 1.0f);
    imguiSlider("Disabled slider", &value2, 0.0, 100.0, 1.0f, Enabled.no);
    imguiIndent();
    imguiLabel("Indented");
    imguiUnindent();
    imguiLabel("Unindented");

    imguiEndScrollArea();

    imguiBeginScrollArea("Scroll area 2", 20 + (1 * scrollAreaWidth), 10, scrollAreaWidth, scrollAreaHeight, &scrollarea2);
    imguiSeparatorLine();
    imguiSeparator();

    foreach (i; 0 .. 100)
        imguiLabel("A wall of text");

    imguiEndScrollArea();

    imguiBeginScrollArea("Scroll area 3", 30 + (2 * scrollAreaWidth), 10, scrollAreaWidth, scrollAreaHeight, &scrollarea3);
    imguiLabel(lastClickInfo);
    imguiEndScrollArea();

    imguiEndFrame();

    const graphicsXPos = 40 + (3 * scrollAreaWidth);

    imguiDrawText(graphicsXPos, scrollAreaHeight, TextAlign.left, "Free text", RGBA(32, 192, 32, 192));
    imguiDrawText(graphicsXPos + 100, windowHeight - 40, TextAlign.right, "Free text", RGBA(32, 32, 192, 192));
    imguiDrawText(graphicsXPos + 50, windowHeight - 60, TextAlign.center, "Free text", RGBA(192, 32, 32, 192));

    imguiDrawLine(graphicsXPos, windowHeight - 80, graphicsXPos + 100, windowHeight - 60, 1.0f, RGBA(32, 192, 32, 192));
    imguiDrawLine(graphicsXPos, windowHeight - 100, graphicsXPos + 100, windowHeight - 80, 2.0, RGBA(32, 32, 192, 192));
    imguiDrawLine(graphicsXPos, windowHeight - 120, graphicsXPos + 100, windowHeight - 100, 3.0, RGBA(192, 32, 32, 192));

    imguiDrawRoundedRect(graphicsXPos, windowHeight - 240, 100, 100, 5.0, RGBA(32, 192, 32, 192));
    imguiDrawRoundedRect(graphicsXPos, windowHeight - 350, 100, 100, 10.0, RGBA(32, 32, 192, 192));
    imguiDrawRoundedRect(graphicsXPos, windowHeight - 470, 100, 100, 20.0, RGBA(192, 32, 32, 192));

    imguiDrawRect(graphicsXPos, windowHeight - 590, 100, 100, RGBA(32, 192, 32, 192));
    imguiDrawRect(graphicsXPos, windowHeight - 710, 100, 100, RGBA(32, 32, 192, 192));
    imguiDrawRect(graphicsXPos, windowHeight - 830, 100, 100, RGBA(192, 32, 32, 192));

    imguiRender(windowWidth, windowHeight);
}
