#include "Ocean.h"

Ocean::Ocean(int grid, int levels, Scene *parent) : Terrain(grid, levels, parent) {
    // this->setName("CDLOD Ocean");
    program.removeAllShaders();
    this->setShader(QOpenGLShader::Vertex, "../glsl/ocean.vert");
    this->setShader(QOpenGLShader::Fragment, "../glsl/ocean.frag");

    QImage decal_ocean("../textures/decal_ocean.jpg");
    // Check whether texture are loaded
    if (decal_ocean.isNull()) {
        qDebug() << "Decal/Height map for ocean has not been found!";
        exit(-1);
    }

    decalmap[0].reset(new QOpenGLTexture(decal_ocean));
    decalmap[0]->setMinificationFilter(QOpenGLTexture::LinearMipMapLinear);
    decalmap[0]->setMagnificationFilter(QOpenGLTexture::Linear);
}

Ocean::~Ocean() {
}

void Ocean::initialize() {
    time.start();
}

void Ocean::uniform() {
    // decalmap[0]->bind(0);
    // int decalLocation0 = program.uniformLocation("uDecalmap0");
    // program.setUniformValue(decalLocation0, 0);

    float elapsedTime = float(time.elapsed()) / 1e3;
    program.setUniformValue("uTime", elapsedTime);

    program.setUniformValue("uGrid", float(grid));

    CHECK_GL_ERROR("after sets uniforms");
    // this->setDrawMode(GL_LINE);
}