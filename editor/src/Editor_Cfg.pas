unit Editor_Cfg;

{$I 'editor.inc'}

interface

type
  TCfg = class(TInterfacedObject)
  strict protected
    function GetLastOpenedFile: string; virtual; abstract;
    procedure SetLastOpenedFile(const AValue: string); virtual; abstract;
  public
    property LastOpenedFile: string
             read GetLastOpenedFile
             write SetLastOpenedFile;
  end;

implementation

end.

