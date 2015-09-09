#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#ifndef __APPLE__
#include <GL/glut.h>
#else
#include <GLUT/glut.h>
#endif
#include <drawtext.h>

#define FONTSZ	18

struct rbnode {
	int red;
	int key;
	void *data;
	struct rbnode *left, *right;
};

struct visinfo {
	float width;
};

void init_gl(int argc, char **argv);
struct rbnode *rbinsert(struct rbnode *tree, int key, void *data);
struct rbnode *bstinsert(struct rbnode *tree, int key, void *data);
struct rbnode *rbrot_left(struct rbnode *a);
struct rbnode *rbrot_right(struct rbnode *a);
struct rbnode *rbfind(struct rbnode *tree, int key);
float rbvis_width(struct rbnode *tree);
void rbvis_draw(struct rbnode *tree, float x, float y);

void draw_roundbox(float xsz, float ysz, float rad, int segm, const float *col, float border, const float *bcol);
void draw_fillet(float rad, int segm);

struct rbnode *tree;
int num_nodes;
struct dtx_font *font;

int main(int argc, char **argv)
{
	int i;

	if(argv[1]) {
		if(!isdigit(argv[1][0])) {
			fprintf(stderr, "pass a fucking number, not: %s\n", argv[1]);
			return 1;
		}
		num_nodes = atoi(argv[1]);
	}

	if(!(font = dtx_open_font("linux-libertine.ttf", FONTSZ))) {
		fprintf(stderr, "failed to open font\n");
		return 1;
	}

	for(i=0; i<num_nodes; i++) {
		int key;
		do {
			key = i;/*rand() % 1024;*/
		} while(rbfind(tree, key));

		tree = rbinsert(tree, key, 0);
	}

	init_gl(argc, argv);
	return 0;
}

struct rbnode *rbinsert(struct rbnode *tree, int key, void *data)
{
	if(!tree) {
		struct rbnode *node = malloc(sizeof *node);
		node->red = 1;
		node->key = key;
		node->data = data;
		node->left = node->right = 0;
		return node;
	}

	/* if 4-node, split it by color inversion */
	if(tree->left &&  tree->left->red && tree->right && tree->right->red) {
		tree->red = !tree->red;
		tree->left->red = !tree->left->red;
		tree->right->red = !tree->right->red;
	}

	if(key < tree->key) {
		tree->left = rbinsert(tree->left, key, data);
	} else if(key > tree->key) {
		tree->right = rbinsert(tree->right, key, data);
	} else {
		tree->data = data;
	}

	/* fix right-leaning reds */
	if(tree->right && tree->right->red) {
		tree = rbrot_left(tree);
	}
	/* fix two reds in a row */
	if(tree->left && tree->left->red && tree->left->left && tree->left->left->red) {
		tree = rbrot_right(tree);
	}

	return tree;
}

struct rbnode *rbrot_left(struct rbnode *a)
{
	struct rbnode *b = a->right;
	a->right = b->left;
	b->left = a;
	b->red = a->red;
	a->red = 1;
	return b;
}

struct rbnode *rbrot_right(struct rbnode *a)
{
	struct rbnode *b = a->left;
	a->left = b->right;
	b->right = a;
	b->red = a->red;
	a->red = 1;
	return b;
}


struct rbnode *bstinsert(struct rbnode *tree, int key, void *data)
{
	if(!tree) {
		struct rbnode *node = malloc(sizeof *node);
		node->red = 0;
		node->key = key;
		node->data = data;
		node->left = node->right = 0;
		return node;
	}

	if(key < tree->key) {
		tree->left = bstinsert(tree->left, key, data);
	} else if(key > tree->key) {
		tree->right = bstinsert(tree->right, key, data);
	} else {
		tree->data = data;
	}

	return tree;
}


struct rbnode *rbfind(struct rbnode *tree, int key)
{
	if(!tree)
		return 0;

	if(key < tree->key) {
		return rbfind(tree->left, key);
	}
	if(key > tree->key) {
		return rbfind(tree->right, key);
	}
	return tree;
}


#define NWIDTH	28.0
#define NHEIGHT 24.0
#define PADDING	0
#define DY	(NHEIGHT + NHEIGHT / 2.0)

#define VIS(node)	((struct visinfo*)(node)->data)

void disp(void);
void reshape(int x, int y);
void keyb(unsigned char key, int x, int y);
void draw_rect(float x, float y, float width, float height, const char *text);
void draw_link(float x0, float y0, float x1, float y1, int red);

void init_gl(int argc, char **argv)
{
	glutInitWindowSize(1280, 720);
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_MULTISAMPLE);

	glutCreateWindow("foo");

	dtx_use_font(font, FONTSZ);

	glutDisplayFunc(disp);
	glutReshapeFunc(reshape);
	glutKeyboardFunc(keyb);

	glEnable(GL_DEPTH_TEST);
	glEnable(GL_MULTISAMPLE);

	glutMainLoop();
}

void disp(void)
{
	glClearColor(0.57, 0.64, 0.59, 1.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	if(tree) {
		rbvis_draw(tree, rbvis_width(tree->left) + NWIDTH, 550);
	}

	glutSwapBuffers();
}

void reshape(int x, int y)
{
	glViewport(0, 0, x, y);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0, x, 0, y, -1, 1);
}

void keyb(unsigned char key, int x, int y)
{
	static int wposx = -1, wposy;

	switch(key) {
	case 27:
		exit(0);

	case 'f':
	case 'F':
		if(wposx >= 0) {
			glutPositionWindow(wposx, wposy);
			wposx = -1;
		} else {
			wposx = glutGet(GLUT_WINDOW_X);
			wposy = glutGet(GLUT_WINDOW_Y);
			glutFullScreen();
		}
		break;

	case 'a':
		tree = rbinsert(tree, num_nodes++, 0);
		glutPostRedisplay();
		break;
	case 'A':
		tree = bstinsert(tree, num_nodes++, 0);
		glutPostRedisplay();
		break;

	case 'r':
	case 'R':
		{
			int x;
			do {
				x = rand() % 1024;
			} while(rbfind(tree, x));

			if(key == 'r') {
				tree = rbinsert(tree, x, 0);
			} else {
				tree = bstinsert(tree, x, 0);
			}
		}
		glutPostRedisplay();
		break;
	}
}

float rbvis_width(struct rbnode *tree)
{
	if(!tree)
		return NWIDTH;

	return NWIDTH + rbvis_width(tree->left) + rbvis_width(tree->right) + PADDING * 3.0;
}

void rbvis_draw(struct rbnode *tree, float x, float y)
{
	float leftx, rightx, nexty;
	static const float hxsz = NWIDTH / 2.0;
	static const float hysz = NHEIGHT / 2.0;
	char text[16];

	if(!tree)
		return;

	leftx = x - (tree->left ? rbvis_width(tree->left->right) + NWIDTH : rbvis_width(tree->left) / 2.0);
	rightx = x + (tree->right ? rbvis_width(tree->right->left) + NWIDTH : rbvis_width(tree->right) / 2.0);

	nexty = y - DY;

	sprintf(text, "%d", tree->key);
	draw_rect(x - hxsz, y - hysz, NWIDTH, NHEIGHT, text);

	rbvis_draw(tree->left, leftx, nexty);
	rbvis_draw(tree->right, rightx, nexty);

	if(tree->left)
		draw_link(x, y, leftx, nexty, tree->left->red);
	if(tree->right)
		draw_link(x, y, rightx, nexty, tree->right->red);
}

void draw_rect(float x, float y, float width, float height, const char *text)
{
	static const float node_col[] = {0.63, 0.71, 0.82, 1.0};
	static const float bord_col[] = {0, 0, 0, 1};


	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glTranslatef(x + width / 2.0, y + height / 2.0, 0.0);

	draw_roundbox(width, height, 8, 6, node_col, 1.2, bord_col);

	glColor3f(0.15, 0.15, 0.15);
	glTranslatef(-dtx_string_width(text) / 2.0, -dtx_string_height(text) / 2.0, 0.1);
	dtx_string(text);
	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
}

void draw_link(float x0, float y0, float x1, float y1, int red)
{
	glPushAttrib(GL_LINE_BIT);
	if(red) {
		glLineWidth(3);
	} else {
		glLineWidth(2);
	}

	glBegin(GL_LINES);
	if(red) {
		glColor3f(0.8, 0.36, 0.3);
	} else {
		glColor3f(0, 0, 0);
	}
	glVertex3f(x0, y0, -0.8);
	glVertex3f(x1, y1, -0.8);
	glEnd();

	glPopAttrib();
}

void draw_roundbox(float xsz, float ysz, float rad, int segm, const float *col, float border, const float *bcol)
{
	float hin_xsz, hin_ysz;

	if(border > 0.0f) {
		glPushMatrix();
		glTranslatef(0, 0, -0.001);
		draw_roundbox(xsz + 2 * border, ysz + 2 * border, rad + border, segm, bcol, 0.0, bcol);
		glPopMatrix();
	}

	/* half inner size */
	hin_xsz = (xsz - 2.0 * rad) / 2.0;
	hin_ysz = (ysz - 2.0 * rad) / 2.0;

	glColor4fv(col);

	glBegin(GL_QUADS);
	/* center */
	glVertex2f(-hin_xsz, -hin_ysz);
	glVertex2f(hin_xsz, -hin_ysz);
	glVertex2f(hin_xsz, hin_ysz);
	glVertex2f(-hin_xsz, hin_ysz);
	/* right */
	glVertex2f(hin_xsz, -hin_ysz);
	glVertex2f(hin_xsz + rad, -hin_ysz);
	glVertex2f(hin_xsz + rad, hin_ysz);
	glVertex2f(hin_xsz, hin_ysz);
	/* top */
	glVertex2f(-hin_xsz, hin_ysz);
	glVertex2f(hin_xsz, hin_ysz);
	glVertex2f(hin_xsz, hin_ysz + rad);
	glVertex2f(-hin_xsz, hin_ysz + rad);
	/* left */
	glVertex2f(-hin_xsz - rad, -hin_ysz);
	glVertex2f(-hin_xsz, -hin_ysz);
	glVertex2f(-hin_xsz, hin_ysz);
	glVertex2f(-hin_xsz - rad, hin_ysz);
	/* bottom */
	glVertex2f(-hin_xsz, -hin_ysz - rad);
	glVertex2f(hin_xsz, -hin_ysz - rad);
	glVertex2f(hin_xsz, -hin_ysz);
	glVertex2f(-hin_xsz, -hin_ysz);
	glEnd();

	glMatrixMode(GL_MODELVIEW);

	glPushMatrix();
	glTranslatef(hin_xsz, hin_ysz, 0);
	draw_fillet(rad, segm);
	glPopMatrix();

	glPushMatrix();
	glTranslatef(-hin_xsz, hin_ysz, 0);
	glRotatef(90, 0, 0, 1);
	draw_fillet(rad, segm);
	glPopMatrix();

	glPushMatrix();
	glTranslatef(-hin_xsz, -hin_ysz, 0);
	glRotatef(180, 0, 0, 1);
	draw_fillet(rad, segm);
	glPopMatrix();

	glPushMatrix();
	glTranslatef(hin_xsz, -hin_ysz, 0);
	glRotatef(270, 0, 0, 1);
	draw_fillet(rad, segm);
	glPopMatrix();
}

void draw_fillet(float rad, int segm)
{
	int i;

	glBegin(GL_TRIANGLE_FAN);
	glVertex2f(0, 0);
	for(i=0; i<segm; i++) {
		float theta = 0.5 * M_PI * (float)i / (float)(segm - 1);
		float x = cos(theta) * rad;
		float y = sin(theta) * rad;
		glVertex2f(x, y);
	}
	glEnd();
}
