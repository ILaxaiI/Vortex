varying float TimeOffset;

#ifdef VERTEX
attribute vec3 InstancePosition;
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
  TimeOffset = InstancePosition.z;
  vertex_position.xy += InstancePosition.xy;
  return transform_projection * vertex_position; ;
}
#endif


#ifdef PIXEL   
  
  uniform ArrayImage MainTex;
  uniform float time;
  uniform int layerCount;
  uniform float timePerLayer;
  void effect(){
  float a = ((TimeOffset + time)/timePerLayer);
  vec3 c = vec3(VaryingTexCoord.xy,floor(a - layerCount * floor(a/layerCount)));
  love_PixelColor = VaryingColor*Texel(MainTex,c);
  
  }
#endif
