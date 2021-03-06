//
// Fonctions utiles pour manipuler les couleurs + noyau destiné au rafraichissement OpenGL
//

// NE PAS MODIFIER
static int4 color_to_int4 (unsigned c)
{
  uchar4 ci = *(uchar4 *) &c;
  return convert_int4 (ci);
}

// NE PAS MODIFIER
static unsigned int4_to_color (int4 i)
{
  uchar4 v = convert_uchar4 (i);
  return *((unsigned *) &v);
}

// NE PAS MODIFIER
static unsigned color_mean (unsigned c1, unsigned c2)
{
  return int4_to_color ((color_to_int4 (c1) + color_to_int4 (c2)) / (int4)2);
}

// NE PAS MODIFIER
static float4 color_scatter (unsigned c)
{
  uchar4 ci;

  ci.s0123 = (*((uchar4 *) &c)).s3210;
  return convert_float4 (ci) / (float4) 255;
}

// NE PAS MODIFIER: ce noyau est appelé lorsqu'une mise à jour de la
// texture de l'image affichée est requise
__kernel void update_texture (__global unsigned *cur, __write_only image2d_t tex)
{
  int y = get_global_id (1);
  int x = get_global_id (0);
  int2 pos = (int2)(x, y);
  unsigned c = cur [y * DIM + x];
#ifdef KERNEL_ssable
  unsigned r = 0, v = 0, b = 0;

  if (c == 1)
    v = 255;
  else if (c == 2)
    b = 255;
  else if (c == 3)
    r = 255;
  else if (c == 4)
    r = v = b = 255;
  else if (c > 4)
    r = v = b = (2 * c);

  c = (r << 24) + (v << 16) + (b << 8) + 0xFF;
#endif
  write_imagef (tex, pos, color_scatter (c));
}

static unsigned not_border(int x, int y) {
  return x > 0 && x < DIM - 1 && y > 0 && y < DIM - 1;
}

static unsigned has_tile_changed(unsigned g, int i, int j, __global unsigned *current) {
  i++;
  j++;
  return current[i+(g+2)*j];
}

static void tile_changed(unsigned g, int i, int j, unsigned value, __global unsigned *previous) {
  i++;
  j++;
  previous[i+(g+2)*j] = value;
}

static int neighborhood_changed(unsigned g, int x, int y, __global unsigned *previous) {

  int n = 0;

  for (int i = y-1; i <= y+1; i++) {
    for (int j = x-1; j <= x+1; j++) {
      n += has_tile_changed(g, j, i, previous);
    }
  }
  return n;
}



