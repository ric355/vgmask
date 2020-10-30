program vgmasktest;

{$mode objfpc}{$H+}

{ Raspberry Pi 3 Application                                                   }
{  Add your program code below, add additional units to the "uses" section if  }
{  required and create new units by selecting File, New Unit from the menu.    }
{                                                                              }
{  To compile your program select Run, Compile (or Run, Build) from the menu.  }

uses
  OpenVG,
  RaspberryPi,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes,
  Ultibo,
  ShellFilesystem,
  ShellUpdate,
  RemoteShell,
  VGShapes,
  dashbootimage;


procedure UpdateMask(Width, Height : Integer; maskingpath : VGPath; Size : integer);
begin
  // first set the mask to cover the whole screen area
  vgMask(0, VG_CLEAR_MASK, 0,0, Width, Height);

  // clear the path. This isn't all that efficient to be honest but we're doing it
  // to demonstrate we can change the mask.
  vgClearPath(maskingpath, VG_PATH_CAPABILITY_ALL);

  // write a new ellipse. Ellipse sizing seems not very accurate. It causes
  // the edge to flicker back and forth as you inrease 'size'. Might be aspect ratio
  // related.
  vguEllipse(maskingPath, Width div 2, Height div 2, Size, Size) ;

  // and render the path onto the mask. We now have a mask with a hole in the middle.
  vgRenderToMask(maskingPath, VG_FILL_PATH or VG_STROKE_PATH, VG_UNION_MASK);
end;

function LoadBootScreen(ImageW, ImageH : integer) : VGImage;
begin
  Result := vgCreateImage(VG_sARGB_8888, ImageW, ImageH, VG_IMAGE_QUALITY_BETTER);

  vgImageSubData(Result, @dashdatablob[1], ImageW*4, VG_sARGB_8888, 0, 0, ImageW, ImageH);
end;

procedure DisplayBootScreen(BootImage : VGImage; Width, Height, ImageW, ImageH : integer);
var
  existingmatrix : array[1..9] of VGFloat;
begin
  VGShapesBackground(0, 0, 0);
  vgSeti(VG_MATRIX_MODE, VG_MATRIX_IMAGE_USER_TO_SURFACE);
  vgGetMatrix(@existingmatrix[1]);

  //the bitmap is upside down in the data structure. This stuff flips it the
  //right way around.

  //mirror in the y direction
  vgScale(1.0, -1.0);

  //move up onto screen so we can see it, and centre it.
  vgTranslate((Width - ImageW) div 2, -ImageH - ((Height - ImageH) div 2));

  vgDrawImage(BootImage);

  vgLoadMatrix(@existingmatrix[1]);

  vgSeti(VG_MATRIX_MODE, VG_MATRIX_PATH_USER_TO_SURFACE);
end;

var
  Width, Height : longint;
  BootImage : VGImage;
  Size : integer;
  MaskingPath : VGPath;
  Direction : integer;

begin
  VGShapesInit(Width,Height);

  vgSeti(VG_MASKING, VG_TRUE);

  BootImage := LoadBootScreen(800, 480);

  maskingPath := vgCreatePath(VG_PATH_FORMAT_STANDARD, VG_PATH_DATATYPE_S_16, 1, 0, 50, 50, VG_PATH_CAPABILITY_ALL);

  Direction :=  1;
  Size := 10;

  while (true) do
  begin
    //logic to make the circle increase and decrease in size.
    size := size + direction;
    if (Size > 720) then
      Direction := -1
    else
    if (Size < 11) then
      Direction := 1;

    // init egl buffers
    VGShapesStart(Width, Height);

    // change mask to new size
    UpdateMask(Width, Height, MaskingPath, Size);

    // draw image - only the part where the mask is set will be visible
    DisplayBootScreen(BootImage, Width, Height, 800, 480);

    // draw size in the middle.
    VGShapesStroke(0,255,0, 1);
    VGShapesFill(0, 255, 0, 1);
    vgshapestext(900, 350, 'Size ' + inttostr(Size), VGShapesSansTypeface, 25);

    // swap egl buffers
    VGShapesEnd;

  end;

  // we never reach here!
  vgdestroypath(maskingpath);

end.

