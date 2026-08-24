package alternativa.proplib.objects
{
   import alternativa.engine3d.alternativa3d;
   import alternativa.engine3d.core.Face;
   import alternativa.engine3d.core.Object3D;
   import alternativa.engine3d.loaders.Parser3DS;
   import alternativa.engine3d.materials.TextureMaterial;
   import alternativa.engine3d.objects.Mesh;
   import alternativa.engine3d.objects.Occluder;
   import alternativa.proplib.utils.ByteArrayMap;
   import alternativa.proplib.utils.TextureByteDataMap;
   import alternativa.utils.textureutils.TextureByteData;
   import flash.utils.ByteArray;
   
   public class PropMesh extends PropObject
   {
      public static var diagnosticTrace:Function;
      
      public static const DEFAULT_TEXTURE:String = "$$$_DEFAULT_TEXTURE_$$$";
      
      public static var threshold:Number = 0.01;
      
      public static var occluderDistanceThreshold:Number = 0.01;
      
      public static var occluderAngleThreshold:Number = 0.01;
      
      public static var occluderConvexThreshold:Number = 0.01;
      
      public static var occluderUvThreshold:int = 1;
      
      public static var meshDistanceThreshold:Number = 0.001;
      
      public static var meshUvThreshold:Number = 0.001;
      
      public static var meshAngleThreshold:Number = 0.001;
      
      public static var meshConvexThreshold:Number = 0.01;
      
      public var textures:TextureByteDataMap;
      
      public var occluders:Vector.<Occluder>;
      
      public function PropMesh(modelData:ByteArray, objectName:String, textureFiles:Object, files:ByteArrayMap, imageMap:TextureByteDataMap)
      {
         super(PropObjectType.MESH);
         traceDiagnostic("PROP_MESH_CONSTRUCTOR modelDataNull=" + (modelData == null) + " objectName=" + objectName + " filesNull=" + (files == null));
         try
         {
            this.parseModel(modelData,objectName,textureFiles,files,imageMap);
            traceDiagnostic("PROP_MESH_CONSTRUCTOR_COMPLETE");
         }
         catch(e:Error)
         {
            traceDiagnostic("PROP_MESH_CONSTRUCTOR_ERROR error=" + e.message + " stack=" + e.getStackTrace());
            throw e;
         }
      }

      private static function traceDiagnostic(param1:String) : void
      {
         if(diagnosticTrace != null)
         {
            diagnosticTrace(param1);
         }
      }
      
      private function parseModel(modelData:ByteArray, objectName:String, textureFiles:Object, files:ByteArrayMap, imageMap:TextureByteDataMap) : void
      {
         var textureName:String = null;
         var textureFileName:String = null;
         var textureByteData:TextureByteData = null;
         traceDiagnostic("PROP_MESH_PROCESS_OBJECTS_START modelDataNull=" + (modelData == null));
         var mesh:Mesh = this.processObjects(modelData,objectName);
         traceDiagnostic("PROP_MESH_PROCESS_OBJECTS_COMPLETE meshNull=" + (mesh == null));
         traceDiagnostic("PROP_MESH_INIT_DEREFERENCE meshNull=" + (mesh == null));
         this.initMesh(mesh);
         this.object = mesh;
         var defaultTextureFileName:String = this.getTextureFileName(mesh);
         if(defaultTextureFileName == null && textureFiles == null)
         {
            throw new Error("PropMesh: no textures found");
         }
         if(textureFiles == null)
         {
            textureFiles = {};
         }
         if(defaultTextureFileName != null)
         {
            textureFiles[PropMesh.DEFAULT_TEXTURE] = defaultTextureFileName;
         }
         this.textures = new TextureByteDataMap();
         for(textureName in textureFiles)
         {
            textureFileName = textureFiles[textureName];
            traceDiagnostic("PROP_MESH_TEXTURE_RESOLVE material=" + textureName + " file=" + textureFileName + " filesNull=" + (files == null) + " imageMapNull=" + (imageMap == null));
            if(imageMap == null)
            {
               textureByteData = new TextureByteData(files.getValue(textureFileName),null);
            }
            else
            {
               textureByteData = imageMap.getValue(textureFileName);
            }
            traceDiagnostic("PROP_MESH_TEXTURE_RESOLVED material=" + textureName + " dataNull=" + (textureByteData == null));
            this.textures.putValue(textureName,textureByteData);
         }
      }
      
      private function processObjects(modelData:ByteArray, objectName:String) : Mesh
      {
         var currObject:Object3D = null;
         var currObjectName:String = null;
         traceDiagnostic("PROP_MESH_MODEL_DATA_DEREFERENCE modelDataNull=" + (modelData == null));
         modelData.position = 0;
         var parser:Parser3DS = new Parser3DS();
         traceDiagnostic("PROP_MESH_3DS_PARSE_START length=" + modelData.length);
         parser.parse(modelData);
         traceDiagnostic("PROP_MESH_3DS_PARSE_COMPLETE objectsNull=" + (parser.objects == null) + " objectCount=" + (parser.objects == null ? -1 : parser.objects.length));
         var objects:Vector.<Object3D> = parser.objects;
         var numObjects:int = int(objects.length);
         var mesh:Mesh = null;
         for(var i:int = 0; i < numObjects; i++)
         {
            currObject = objects[i];
            traceDiagnostic("PROP_MESH_OBJECT index=" + i + " objectNull=" + (currObject == null) + " nameNull=" + (currObject == null || currObject.name == null));
            currObjectName = currObject.name.toLowerCase();
            if(currObjectName.indexOf("occl") == 0)
            {
               this.addOccluder(Mesh(currObject));
            }
            else if(objectName == currObjectName)
            {
               mesh = Mesh(currObject);
            }
         }
         traceDiagnostic("PROP_MESH_FALLBACK selectedNull=" + (mesh == null) + " firstObjectNull=" + (objects.length == 0 || objects[0] == null));
         return mesh != null ? mesh : Mesh(objects[0]);
      }
      
      private function getTextureFileName(mesh:Mesh) : String
      {
         var material:TextureMaterial = null;
         var face:Face = mesh.alternativa3d::faceList;
         while(face != null)
         {
            material = face.material as TextureMaterial;
            if(material != null)
            {
               return material.diffuseMapURL.toLowerCase();
            }
            face = face.alternativa3d::next;
         }
         return null;
      }
      
      private function addOccluder(mesh:Mesh) : void
      {
         mesh.weldVertices(occluderDistanceThreshold,occluderUvThreshold);
         mesh.weldFaces(occluderAngleThreshold,occluderUvThreshold,occluderConvexThreshold);
         var occluder:Occluder = new Occluder();
         occluder.createForm(mesh,true);
         occluder.x = mesh.x;
         occluder.y = mesh.y;
         occluder.z = mesh.z;
         occluder.rotationX = mesh.rotationX;
         occluder.rotationY = mesh.rotationY;
         occluder.rotationZ = mesh.rotationZ;
         if(this.occluders == null)
         {
            this.occluders = new Vector.<Occluder>();
         }
         this.occluders.push(occluder);
      }
      
      private function initMesh(mesh:Mesh) : void
      {
         mesh.weldVertices(meshDistanceThreshold,meshUvThreshold);
         mesh.weldFaces(meshAngleThreshold,meshUvThreshold,meshConvexThreshold);
         mesh.threshold = threshold;
      }
      
      override public function traceProp() : void
      {
         var textureName:String = null;
         var textureData:TextureByteData = null;
         super.traceProp();
         for(textureName in this.textures)
         {
            textureData = this.textures[textureName];
            trace("\t" + textureName,textureData.diffuseData.bytesAvailable,textureData.opacityData);
         }
      }
   }
}
