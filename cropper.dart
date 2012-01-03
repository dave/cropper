#import('dart:html');

class cropper {

  int CropWidth, CropHeight, ImageWidth, ImageHeight, XOffset, YOffset = 0;
  double Zoom = 0.0;
  String ImageUrl = "";
  bool AllowCustomHeight, AllowCustomWidth = false;
  int ImageOriginalWidth, ImageOriginalHeight, MaxWidth, MaxHeight, MinWidth, MinHeight = 0;
  ImageElement Image;
  InputElement Slider;
  DivElement Main;
  CanvasElement Canvas;
  CanvasRenderingContext2D Ctx;
  int MainWidth, MainHeight = 0;
  String ControlPrefix = "";
  
  Area ImageArea, CropArea, CornerHandleArea, WidthHandleArea, HeightHandleArea;
  
  cropper() {
  }

  void init() {
    
    InputElement controlPrefixHidden = document.query('#cropperControlPrefix');
    ControlPrefix = controlPrefixHidden.value;
    
    CropWidth = getInt('CropWidth');
    CropHeight = getInt('CropHeight');
    ImageWidth = getInt('ImageWidth');
    ImageHeight = getInt('ImageHeight');
    XOffset = getInt('XOffset');
    YOffset = getInt('YOffset');
    Zoom = getDouble('Zoom');
    
    ImageUrl = getString('ImageUrl');
    ImageOriginalWidth = getInt('ImageOriginalWidth');
    ImageOriginalHeight = getInt('ImageOriginalHeight');
    AllowCustomHeight = getBool('AllowCustomHeight');
    AllowCustomWidth = getBool('AllowCustomWidth');
    MaxWidth = getInt('MaxWidth');
    MaxHeight = getInt('MaxHeight');
    MinWidth = getInt('MinWidth');
    MinHeight = getInt('MinHeight');
    
    //document.query('#status1').innerHTML = "CropWidth: $CropWidth, CropHeight: $CropHeight, ImageWidth: $ImageWidth, ImageHeight: $ImageHeight, XOffset: $XOffset, YOffset: $YOffset, Zoom: $Zoom";
    //document.query('#status2').innerHTML = "ImageUrl: $ImageUrl";
    //document.query('#status3').innerHTML = "AllowCustomHeight: $AllowCustomHeight, AllowCustomWidth: $AllowCustomWidth, MaxWidth: $MaxWidth, MaxHeight: $MaxHeight, MinWidth: $MinWidth, MinHeight: $MinHeight";
    
    Slider = document.query('#' + ControlPrefix + 'Slider');
    Slider.value = Zoom.toString();
    Slider.on.change.add((Event event) {
      Zoom = Math.parseDouble(Slider.value);
      testZoomExtents();
      updateImage();
    }, true);
    Image = document.query('#' + ControlPrefix + 'Image');
    Main = document.query('#' + ControlPrefix + 'Main');
    Canvas = document.query('#' + ControlPrefix + 'Canvas');
    Ctx = Canvas.getContext('2d');
    
    
    //Canvas.on.mouseOut.add((Event e){wind});
    Canvas.on.mouseMove.add(mouseMove);
    Canvas.on.mouseDown.add(mouseDown);
    Canvas.on.mouseUp.add(mouseUpOut);
    Canvas.on.mouseOut.add(mouseUpOut);
    
    Canvas.style.cursor = "move";
    
    Main.style.display = "";
    
    Main.rect.then((ElementRect r){
      MainWidth = r.client.width;
      MainHeight = r.client.height;
      
      updateImage();
      //testImageExtents();
      //updateImage();
      
      testCropExtents();
      updateCrop();
      
    }); 
    
    
  }
  bool DraggingImage, DraggingCornerHandle, DraggingWidthHandle, DraggingHeightHandle = false;
  Pixel DraggingStart;
  int CropWidthAtStartOfDrag, CropHeightAtStartOfDrag, ImageXOffsetAtStartOfDrag, ImageYOffsetAtStartOfDrag;
  Pixel ImageTopLeft;
  void mouseUpOut(MouseEvent e)
  {
    DraggingImage = false;  
    DraggingCornerHandle = false;
    DraggingWidthHandle = false;
    DraggingHeightHandle = false;
  }
  void mouseMove(MouseEvent e)
  {
    int x = e.offsetX;
    int y = e.offsetY;
    //document.query('#status4').innerHTML = "x: $x, y: $y)";
    
    Pixel p = new Pixel(x, y);
    
    if (DraggingImage || DraggingCornerHandle || DraggingWidthHandle || DraggingHeightHandle)
    {
      int deltaX = p.x - DraggingStart.x;
      int deltaY = p.y - DraggingStart.y;
      if (DraggingCornerHandle || DraggingWidthHandle || DraggingHeightHandle)
      {
        if (DraggingCornerHandle || DraggingWidthHandle)
        {
          CropWidth = CropWidthAtStartOfDrag + (deltaX * 2);
        }
        
        if (DraggingCornerHandle || DraggingHeightHandle)
        {
          CropHeight = CropHeightAtStartOfDrag + (deltaY * 2);
        }
        
        testCropExtents();
        
        updateCrop();
      }
      else if (DraggingImage)
      {
        XOffset = ImageXOffsetAtStartOfDrag + deltaX;
        YOffset = ImageYOffsetAtStartOfDrag + deltaY;
        testImageExtents();
        updateImage();
      }
    }
    
    if (p.In(CornerHandleArea))
    {
      Canvas.style.cursor = "se-resize";
    }
    else if (p.In(WidthHandleArea))
    {
      Canvas.style.cursor = "e-resize";
    }
    else if (p.In(HeightHandleArea))
    {
      Canvas.style.cursor = "s-resize";
    }
    else if (p.In(ImageArea))
    {
      Canvas.style.cursor = "move";
    }
    else
    {
      Canvas.style.cursor = "";
    }
  }
  void testImageExtents()
  {
    int maxXOffset = ((Image.width - CropWidth) / 2.0).toInt();
    int maxYOffset = ((Image.height - CropHeight) / 2.0).toInt();
    
    if (XOffset > maxXOffset)
      XOffset = maxXOffset;
    
    if (XOffset < -maxXOffset)
      XOffset = -maxXOffset;
    
    if (YOffset > maxYOffset)
      YOffset = maxYOffset;
    
    if (YOffset < -maxYOffset)
      YOffset = -maxYOffset;
    
    
  }
  void testCropExtents()
  {
    int maxCropWidth = (((Image.width / 2.0) - Math.max(XOffset, -XOffset).toInt()) * 2).toInt();
    int maxCropHeight = (((Image.height / 2.0) - Math.max(YOffset, -YOffset).toInt()) * 2).toInt();
    
    if (CropWidth > maxCropWidth)
      CropWidth = maxCropWidth;
    
    if (CropHeight > maxCropHeight)
      CropHeight = maxCropHeight;
    
    if (CropWidth > MaxWidth)
      CropWidth = MaxWidth;
    
    if (CropWidth < MinWidth)
      CropWidth = MinWidth;
    
    if (CropHeight > MaxHeight)
      CropHeight = MaxHeight;
    
    if (CropHeight < MinHeight)
      CropHeight = MinHeight;
  }
  void testZoomExtents()
  {
    int minImageWidth = (((CropWidth / 2.0) + Math.max(XOffset, -XOffset).toInt()) * 2).toInt();
    int minImageHeight = (((CropHeight / 2.0) + Math.max(YOffset, -YOffset).toInt()) * 2).toInt();
    
    double minWidthZoom = minImageWidth / ImageOriginalWidth * 100;
    double minHeightZoom = minImageHeight / ImageOriginalHeight * 100;
    
    double minZoom = Math.max(minWidthZoom, minHeightZoom);
    
    if (Zoom < minZoom)
    {
      Slider.value = minZoom.ceil().toInt().toString();
      Zoom = minZoom;
    }
    
  }
                       
  void mouseDown(MouseEvent e)
  {
    int x = e.offsetX;
    int y = e.offsetY;
    Pixel p = new Pixel(x, y);
    
    if (p.In(CornerHandleArea))
    {
      DraggingCornerHandle = true;
      DraggingStart = p;
      CropWidthAtStartOfDrag = CropWidth;
      CropHeightAtStartOfDrag = CropHeight;
    }
    else if (p.In(WidthHandleArea))
    {
      DraggingWidthHandle = true;
      DraggingStart = p;
      CropWidthAtStartOfDrag = CropWidth;
    }
    else if (p.In(HeightHandleArea))
    {
      DraggingHeightHandle = true;
      DraggingStart = p;
      CropHeightAtStartOfDrag = CropHeight;
    }
    else if (p.In(ImageArea))
    {
      DraggingImage = true;
      DraggingStart = p;
      ImageXOffsetAtStartOfDrag = XOffset;
      ImageYOffsetAtStartOfDrag = YOffset;
    }
  }
  void updateCrop()
  {
    Ctx.clearRect(0, 0, MainWidth, MainHeight);
    
    Ctx.setAlpha(0.7);
    Ctx.setFillColor('white');
    
    Ctx.fillRect(0, 0, MainWidth, MainHeight);
    
    Ctx.clearRect((MainWidth / 2) - (CropWidth / 2), (MainHeight / 2) - (CropHeight / 2), CropWidth, CropHeight);
    
//    if (AllowCustomWidth || AllowCustomHeight)
//    {
//      //draw corner handle
//      Ctx.setAlpha(0.8);
//      Ctx.setFillColor('red');
//      Ctx.beginPath();
//      Ctx.moveTo((MainWidth / 2) + (CropWidth / 2) - 20, (MainHeight / 2) + (CropHeight / 2));
//      Ctx.lineTo((MainWidth / 2) + (CropWidth / 2), (MainHeight / 2) + (CropHeight / 2));
//      Ctx.lineTo((MainWidth / 2) + (CropWidth / 2), (MainHeight / 2) + (CropHeight / 2) - 20);
//      Ctx.closePath();
//      Ctx.fill();
//    }
    
    if (AllowCustomWidth)
    {
      //draw width handle
      Ctx.setAlpha(0.2);
      Ctx.setFillColor('red');
      Ctx.beginPath();
      Ctx.arc((MainWidth / 2) + (CropWidth / 2), MainHeight / 2, 15, 0, Math.PI * 2, true);
      Ctx.closePath();
      Ctx.fill();
      WidthHandleArea = new Area((MainWidth / 2) + (CropWidth / 2) - 15, (MainHeight / 2) - 15, 30, 30);
    }
    
    if (AllowCustomHeight)
    {
      //draw height handle
      Ctx.setAlpha(0.2);
      Ctx.setFillColor('red');
      Ctx.beginPath();
      Ctx.arc(MainWidth / 2, (MainHeight / 2) + (CropHeight / 2), 15, 0, Math.PI * 2, true);
      Ctx.closePath();
      Ctx.fill();
      HeightHandleArea = new Area((MainWidth / 2) - 15, (MainHeight / 2) + (CropHeight / 2) - 15, 30, 30);
    }
    
    if (AllowCustomHeight && AllowCustomWidth)
    {
      //draw corner handle
      Ctx.setAlpha(0.2);
      Ctx.setFillColor('red');
      Ctx.beginPath();
      Ctx.arc((MainWidth / 2) + (CropWidth / 2), (MainHeight / 2) + (CropHeight / 2), 15, 0, Math.PI * 2, true);
      Ctx.closePath();
      Ctx.fill();
      CornerHandleArea = new Area((MainWidth / 2) + (CropWidth / 2) - 15, (MainHeight / 2) + (CropHeight / 2) - 15, 30, 30);
    }
    
    
    
  }
  
  void updateImage()
  {
    
    if (Image.src != ImageUrl)
      Image.src = ImageUrl;
    
    Image.width = (ImageOriginalWidth * Zoom / 100.0).toInt();
    Image.height = (ImageOriginalHeight * Zoom / 100.0).toInt();
    
    int left = ((MainWidth / 2) + XOffset - (Image.width / 2)).toInt();
    int top = ((MainHeight / 2) + YOffset - (Image.height / 2)).toInt();
    
    ImageTopLeft = new Pixel(left, top);
    
    Image.style.left = ImageTopLeft.x.toString() + "px";
    Image.style.top = ImageTopLeft.y.toString() + "px";
    
    ImageArea = new Area(left, top, Image.width, Image.height);
    
  }
  int getInt(String name){
    InputElement i = document.query('#'+ControlPrefix+name);
    return Math.parseInt(i.value);
  }
  double getDouble(String name){
    InputElement i = document.query('#'+ControlPrefix+name);
    return Math.parseDouble(i.value);
  }
  bool getBool(String name){
    InputElement i = document.query('#'+ControlPrefix+name);
    return i.value == "true";
  }
  String getString(String name){
    InputElement i = document.query('#'+ControlPrefix+name);
    return i.value;
  }

}

class Pixel
{
  int x, y;
  Pixel(this.x, this.y);
  bool In(Area a)
  {
    return a != null && x >= a.left && x < (a.left + a.width) && y >= a.top && y < (a.top + a.height);
  }
}
class Area
{
  int top, left, width, height = 0;
  Area(this.left, this.top, this.width, this.height);
//  bool In(int x, y)
//  {
//    return x >= left && x < (left + width) && y >= top && y < (top + height);
//  }
}

void main() {  
  new cropper().init();
}
