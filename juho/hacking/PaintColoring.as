package juho.hacking
{
   import platform.client.fp10.core.resource.types.ImageResource;
   import platform.client.fp10.core.resource.types.MultiframeImageResource;
   import projects.tanks.clients.flash.commons.models.coloring.IColoring;

   public class PaintColoring implements IColoring
   {
      private var coloring:ImageResource;

      private var animatedColoring:MultiframeImageResource;

      public function PaintColoring(param1:Object)
      {
         this.coloring = param1 as ImageResource;
         this.animatedColoring = param1 as MultiframeImageResource;
      }

      public function isAnimated() : Boolean
      {
         return this.animatedColoring != null;
      }

      public function getColoring() : ImageResource
      {
         return this.coloring;
      }

      public function getAnimatedColoring() : MultiframeImageResource
      {
         return this.animatedColoring;
      }
   }
}
