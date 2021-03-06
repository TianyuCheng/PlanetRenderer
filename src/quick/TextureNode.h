/** This file comes from a part of "Texture in Thread" Example of the Qt Toolkit. **/
#ifndef TEXTURE_NODE_H
#define TEXTURE_NODE_H

#include <QtCore/QObject>
#include <QtCore/QSize>
#include <QtCore/QMutex>
#include <QtQuick/QSGSimpleTextureNode> 
#include <QtQuick/QQuickWindow> 

class TextureNode : public QObject, public QSGSimpleTextureNode
{
	Q_OBJECT
public:
	TextureNode(QQuickWindow *window)
		: m_id(0), m_size(0, 0), m_texture(0), m_window(window)
	{
		// Our texture node must have a texture, so use the default 0
		// texture.
		m_texture = m_window->createTextureFromId(0, QSize(1, 1));
		setTexture(m_texture);
		setFiltering(QSGTexture::Linear);
		// We do flip in QML, not here.
		// Always prefer Qt Quick's solution
		//setTextureCoordinatesTransform(QSGSimpleTextureNode::MirrorVertically);
	}

	~TextureNode()
	{
		delete m_texture;
	}

signals:
	void textureInUse();
	void pendingNewTexture();

public slots:

	// This function gets called on the FBO rendering thread and will
	// store the texture id and size and schedule an update on the window.
	void newTexture(int id, const QSize &size) {
		m_mutex.lock();
		m_id = id;
		m_size = size;
		m_mutex.unlock();

		// We cannot call QQuickWindow::update directly here, as this
		// is only allowed from the rendering thread or GUI thread.
		emit pendingNewTexture();
	}

	// Before the scene graph starts to render, we update to the pending texture
	void prepareNode() {
		m_mutex.lock();
		int newId = m_id;
		QSize size = m_size;
		m_id = 0;
		m_mutex.unlock();
		if (newId) {
			delete m_texture;
			m_texture = m_window->createTextureFromId(newId, size);
			setTexture(m_texture);

			markDirty(DirtyMaterial);

			// This will notify the rendering thread that the
			// texture is now being rendered and it can start
			// rendering to the other one.
			emit textureInUse();
		}
	}

private:
	int m_id;
	QSize m_size;

	QMutex m_mutex;

	QSGTexture *m_texture;
	QQuickWindow *m_window;
};

#endif
