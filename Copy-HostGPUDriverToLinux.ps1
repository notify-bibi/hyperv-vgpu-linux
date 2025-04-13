param(
    [string]$VMName = $null,
    [string]$vmusername = "ar",
    [string]$vmip = $null,
    [string]$instargs = "",
    [string]$remote_tempdir = "/tmp/wsl/"
)

function xscp {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$SourcePath,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$DestinationPath,

        [Parameter(Mandatory=$false)]
        [Alias("exclude")]
        [string[]]$ExcludePattern
    )

    # 验证 SCP 命令可用性
    if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
        Write-Error "需要安装 OpenSSH 客户端 (包含 scp 命令)"
        return
    }

    # 验证源路径存在
    if (-not (Test-Path $SourcePath)) {
        Write-Error "源路径不存在: $SourcePath"
        return
    }

    # 无排除参数时直接传输
    if (-not $ExcludePattern) {
        try {
            Write-Host "直接使用 SCP 传输..." -ForegroundColor Cyan
            & scp -r $SourcePath $DestinationPath
            Write-Host "传输完成" -ForegroundColor Green
            return
        }
        catch {
            Write-Error "SCP 传输失败: $_"
            return
        }
    }

    # 有排除参数时使用临时目录
    $tempDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
    $tempSource = Join-Path $tempDir (Split-Path $SourcePath -Leaf)

    try {
        # 创建临时副本
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        Copy-Item -Path $SourcePath -Destination $tempDir -Recurse -Force

        # 删除排除文件
        Get-ChildItem -Path $tempSource -Include $ExcludePattern -File -Recurse | ForEach-Object {
            Write-Verbose "排除文件: $($_.FullName)"
            Remove-Item $_.FullName -Force
        }

        # 执行 SCP 传输
        Write-Host "使用预处理副本传输...  scp -r $tempSource $DestinationPath" -ForegroundColor Cyan
        & scp -r $tempSource $DestinationPath
        Write-Host "传输完成 (已排除: $($ExcludePattern -join ', '))" -ForegroundColor Green
    }
    catch {
        Write-Error "传输失败: $_"
    }
    finally {
        # 清理临时目录
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
    }
}

# define your vmip, vmusername and currentdriverfolder
$vmusername = "ar"
$vmip = "archlinux.mshome.net"
$remote = "${vmusername}@${vmip}"

type $env:USERPROFILE\.ssh\id_rsa.pub | ssh "$remote" "tee ~/.ssh/authorized_keys"

# Get-CimInstance -ClassName Win32_VideoController -Property *

ssh "$remote" "rm -rf $remote_tempdir && mkdir -p $remote_tempdir && mkdir -p $remote_tempdir/drivers"
(Get-CimInstance -ClassName Win32_VideoController -Property *).InstalledDisplayDrivers | Select-String "C:\\Windows\\System32\\DriverStore\\FileRepository\\[a-zA-Z0-9\\._]+\\" | foreach {
    $l = $_.Matches.Value.Substring(0, $_.Matches.Value.Length - 1)
}
$driverfolders = (Get-CimInstance -ClassName Win32_VideoController -Property *).InstalledDisplayDrivers |
    Where-Object { $_ -match "C:\\Windows\\System32\\DriverStore\\FileRepository\\([^\\]+)" } |
    ForEach-Object {
        $folderPath = "C:\Windows\System32\DriverStore\FileRepository\" + $matches[1]
        $folderPath
    } |
    Select-Object -Unique

if ($driverfolders -and $driverfolders.Count -gt 0) {
    Write-Host "[SUCCESS] Found $($driverfolders.Count) unique driver folders."
}
else {
    Write-Host "[ERROR] No driver folders found in the C:\\Windows\\System32\\DriverStore\\FileRepository !" -ForegroundColor Red
    exit 1  # 可选：如果失败则退出脚本
}

foreach ($driverfolder in $driverfolders) {
    echo "Current DisplayDrivers: $driverfolder"
    xscp -exclude '*.dll','*.exe','*.sys' -SourcePath "${driverfolder}" -DestinationPath "${remote}:${remote_tempdir}drivers/"
}

# Use scp to copy Windows Host drivers to Ubuntu VM
scp -r "C:\Windows\System32\lxss\lib" "${remote}:$remote_tempdir"
scp -r "C:\Program Files\WSL\lib" "${remote}:${remote_tempdir}libwsl"

scp ".\install-drivers.sh" "${remote}:/tmp/"
scp ".\install-dxgkrnl.sh" "${remote}:$remote_tempdir"
scp ".\test_gpu.sh" "${remote}:~/.local/bin"
ssh "$remote" "chmod +x /tmp/install-drivers.sh $remote_tempdir/install-dxgkrnl.sh ~/.local/bin/test_gpu.sh"

if (! $VMName -eq $null) {
    Start-Process "vmconnect" "localhost", "$VMName" -WindowStyle Normal
}

echo "done"
echo "Later: /tmp/install-drivers.sh ${instargs}"
echo "Later: /usr/lib/wsl/install-dxgkrnl.sh"
echo "Later: test_gpu.sh"