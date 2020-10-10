unit SudokuUnit;

{****************************************************************************
                    Sudoku-Lazarus

My very old project on Lazarus for solving sudoku. Doesn't use recursion
and backtracking. Uses only simple logical rules (vertical, horizontal and
block elimination method), therefore only solves simple Sudoku.

https://github.com/pitelf/Sudoku-Lazarus

****************************************************************************}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids, Types;

type
  TNums = set of 1 .. 9;
  TPole = array [1 .. 9, 1 .. 9] of TNums;
  TBPole = array [1 .. 9, 1 .. 9] of integer;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnSaveState: TButton;
    btnSolve: TButton;
    btnClearField: TButton;
    btnOpenState: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    StringGrid1: TStringGrid;
    procedure btnSaveStateClick(Sender: TObject);
    procedure btnSolveClick(Sender: TObject);
    procedure btnClearFieldClick(Sender: TObject);
    procedure btnOpenStateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1DrawCell(Sender: TObject; aCol, aRow: integer;
      aRect: TRect; aState: TGridDrawState);
  private
    Pole: TPole;
    BPole: TBPole;
    procedure InitPole;
    procedure PutNum(const X, Y, Num: integer);
    procedure WritePole;
    procedure ReadPole;
    procedure CheckPole;
    procedure checkHorizontal(const X: integer);
    procedure checkVertical(const Y: integer);
    procedure checkSquare(const S: integer);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

//////////////////
// View
//////////////////

procedure TfrmMain.btnSolveClick(Sender: TObject);
begin
  InitPole;
  ReadPole;
  WritePole;
end;

procedure TfrmMain.btnSaveStateClick(Sender: TObject);
var
  F: file of TPole;
begin
  if SaveDialog1.Execute then
  begin
    AssignFile(F, SaveDialog1.FileName);
    Rewrite(F);
    Write(F, Pole);
    CloseFile(F);
  end;
end;

procedure TfrmMain.btnClearFieldClick(Sender: TObject);
var
  iX, iY: integer;
begin
  for iX := 1 to 9 do
    for iY := 1 to 9 do
      StringGrid1.Cells[iY - 1, iX - 1] := '';
end;

procedure TfrmMain.btnOpenStateClick(Sender: TObject);
var
  F: file of TPole;
begin
  if OpenDialog1.Execute then
  begin
    AssignFile(F, OpenDialog1.FileName);
    Reset(F);
    Read(F, Pole);
    CloseFile(F);
    WritePole;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  OpenDialog1.InitialDir := ExtractFileDir(Application.ExeName) + '\SavedStates';
  SaveDialog1.InitialDir := ExtractFileDir(Application.ExeName) + '\SavedStates';
end;

procedure TfrmMain.StringGrid1DrawCell(Sender: TObject; aCol, aRow: integer;
  aRect: TRect; aState: TGridDrawState);
begin
  if ((ACol < 3) and (ARow > 2) and (ARow < 6)) or
    ((ACol > 2) and (ACol < 6) and (ARow < 3)) or
    ((ARow > 2) and (ARow < 6) and (ACol > 5)) or
    ((ACol > 2) and (ACol < 6) and (ARow > 5)) then
    with TStringGrid(Sender) do
    begin
      // paint the background Green
      Canvas.Brush.Color := clMoneyGreen;
      Canvas.FillRect(aRect);
      Canvas.TextOut(aRect.Left + 2, aRect.Top + 2, Cells[ACol, ARow]);
    end;
end;

//////////////////
// Logic
//////////////////

procedure TfrmMain.InitPole;
var
  iX, iY, iC: integer;
begin
  for iX := 1 to 9 do
    for iY := 1 to 9 do
      for iC := 1 to 9 do
      begin
        Include(Pole[iX, iY], iC);
      end;
  FillChar(BPole, SIZEOF(BPole), #0);
end;

procedure TfrmMain.PutNum(const X, Y, Num: integer);
var
  iX, iY: integer;
begin
  if BPole[X, Y] = 1 then
    exit;
  for iX := 1 to 9 do
    if iX <> X then
      Exclude(Pole[iX, Y], Num);
  for iY := 1 to 9 do
    if iY <> Y then
      Exclude(Pole[X, iY], Num);
  for iX := 1 + 3 * ((X - 1) div 3) to 3 + 3 * ((X - 1) div 3) do
    for iY := 1 + 3 * ((Y - 1) div 3) to 3 + 3 * ((Y - 1) div 3) do
      if (iX <> X) and (iY <> Y) then
        Exclude(Pole[iX, iY], Num);
  Pole[X, Y] := [Num];
  BPole[X, Y] := 1;
  CheckPole;

end;

procedure TfrmMain.WritePole;
var
  iX, iY: integer;

  function getNum(nums: TNums): string;
  var
    iC: integer;
  begin
    for iC := 1 to 9 do
      if nums = [iC] then
      begin
        Result := IntToStr(iC);
        exit;
      end;
    Result := '';
  end;

begin
  for iX := 1 to 9 do
    for iY := 1 to 9 do
      StringGrid1.Cells[iY - 1, iX - 1] := getNum(Pole[iX, iY]);
end;


procedure TfrmMain.ReadPole;
var
  iX, iY, Num, errCode: integer;
begin
  for iX := 1 to 9 do
    for iY := 1 to 9 do
    begin
      val(StringGrid1.Cells[iY - 1, iX - 1], Num, errCode);
      if (errCode = 0) and (Num in [1 .. 9]) then
        PutNum(iX, iY, Num);
    end;
end;

procedure TfrmMain.CheckPole;
var
  iC, I: integer;
begin
  for I := 1 to 3 do
  begin
    for iC := 1 to 9 do
    begin
      checkHorizontal(iC);
      checkVertical(iC);
      checkSquare(iC);
    end;
  end;
end;

procedure TfrmMain.checkHorizontal(const X: integer);
var
  iNum: integer;
  iY, tempY, temp: integer;
begin
  tempY := 1;
  for iNum := 1 to 9 do
  begin
    temp := 0;
    for iY := 1 to 9 do
    begin
      if iNum in Pole[X, iY] then
      begin
        Inc(temp);
        if (temp > 1) then
          break;
        tempY := iY;
      end;
    end;
    if ((temp = 1) and (BPole[X, tempY] = 0)) then
      PutNum(X, tempY, iNum);
  end;
end;

procedure TfrmMain.checkVertical(const Y: integer);
var
  iNum: integer;
  iX, tempX, temp: integer;
begin
  tempX := 1;
  for iNum := 1 to 9 do
  begin
    temp := 0;
    for iX := 1 to 9 do
    begin
      if iNum in Pole[iX, Y] then
      begin
        Inc(temp);
        if (temp > 1) then
          break;
        tempX := iX;
      end;
    end;
    if ((temp = 1) and (BPole[tempX, Y] = 0)) then
      PutNum(tempX, Y, iNum);
  end;

end;

procedure TfrmMain.checkSquare(const S: integer);
var
  X, Y, iX, iY, iNum, temp, tempX, tempY: integer;
begin
  tempX := 1;
  tempY := 1;
  X := ((S - 1) div 3) + 1;
  Y := ((S - 1) mod 3) + 1;
  for iNum := 1 to 9 do
  begin
    temp := 0;
    for iX := 3 * X - 2 to 3 * X do
      for iY := 3 * Y - 2 to 3 * Y do
      begin
        if iNum in Pole[iX, iY] then
        begin
          Inc(temp);
          if (temp > 1) then
            break;
          tempX := iX;
          tempY := iY;
        end;
      end;
    if ((temp = 1) and (BPole[tempX, tempY] = 0)) then
      PutNum(tempX, tempY, iNum);
  end;

end;

end.

