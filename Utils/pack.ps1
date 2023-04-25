$VERSION="$VERSION"
if ($VERSION -eq "") { $VERSION="1.0" }
echo $(
rd nil.Exev\bin -Force -Recurse -erroraction 'silentlycontinue'
rd nil.Exev\obj -Force -Recurse -erroraction 'silentlycontinue'
mkdir nuget -erroraction 'silentlycontinue'
) > $null
$REVISION=$(git rev-list --count origin/master)
echo "VERSION: $VERSION.$REVISION"
[System.IO.File]::WriteAllText("$(get-location)\\NiL.Exev\\Properties\\InternalInfo.cs","internal static class InternalInfo
{
    internal const string Version = ""$VERSION.$($REVISION)"";
    internal const string Year = ""$(get-date -Format yyyy)"";
}")
cd NiL.Exev
dotnet run --project ./../Utils/tiny-t4/tiny-t4.csproj --framework net7.0
dotnet build -c Release -property:VersionPrefix=$VERSION.$($REVISION) -property:SignAssembly=true
dotnet pack -c Release -property:VersionPrefix=$VERSION.$($REVISION) -property:SignAssembly=true
mv -Force bin/release/NiL.Exev.$VERSION.$($REVISION).nupkg ../nuget/NiL.Exev.$VERSION.$($REVISION).nupkg
cd ..