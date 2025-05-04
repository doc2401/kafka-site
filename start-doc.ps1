# 查找所有documentation.html文件并下载对应的Kafka文档
# 作者：Trae AI
# 日期：2025-05-04



# Get-ChildItem -Path . -Recurse -Filter "documentation.html" -File
# Invoke-WebRequest -Uri "https://kafka.apache.org/40/documentation/" -OutFile "40/documentation2.html"




# 基础URL
$baseUrl = "https://kafka.apache.org"

# 设置要查找的文件名
$findFile = "documentation.html"
# 设置下载的文件名
$downloadFile = "documentation2.html"
# 设置转换链接的文件名
$changeFile = "documentation3.html"

# 查找当前目录及子目录中的所有documentation.html文件
Write-Host "正在查找所有documentation.html文件..." -ForegroundColor Cyan
$docFiles = Get-ChildItem -Path . -Recurse -Filter $findFile -File

if ($docFiles.Count -eq 0) {
    Write-Host "未找到任何documentation.html文件。" -ForegroundColor Yellow
    exit
}

Write-Host "找到 $($docFiles.Count) 个documentation.html文件。" -ForegroundColor Green

# 只保留最后两个文件
$docFiles = $docFiles | Select-Object -Last 2


# 创建一个计数器来跟踪下载进度
$counter = 0
$total = $docFiles.Count

# 遍历每个找到的文件
foreach ($file in $docFiles) {
    $counter++
    
    # 获取文件的相对路径（相对于当前目录）
    $relativePath = $file.DirectoryName.Substring((Get-Location).Path.Length + 1)
    
    # 如果相对路径为空，则设置为根目录
    if ([string]::IsNullOrEmpty($relativePath)) {
        $relativePath = ""
    }
    else {
        # 确保路径以/结尾
        $relativePath = $relativePath.Replace("\", "/")
        if (-not $relativePath.EndsWith("/")) {
            $relativePath = "$relativePath/"
        }
    }
    
    # 构建完整的URL
    $url = "$baseUrl/$relativePath/$($file.Name)"
 
    # 构建目标文件路径
    $targetDir = $file.DirectoryName
    $targetFile = Join-Path -Path $targetDir -ChildPath $downloadFile
    
    # 显示下载信息
    Write-Host "[$counter/$total] 正在下载: $url" -ForegroundColor Cyan
    Write-Host "  保存到: $targetFile" -ForegroundColor Gray
    
    
    # 下载文件
    Invoke-WebRequest -Uri $url -OutFile $targetFile -ErrorAction Stop
    Write-Host "  下载成功！" -ForegroundColor Green
   
    # 读取文件内容
    $content = Get-Content -Path $targetFile -Raw -Encoding UTF8
    # 执行替换
    $content = $content -replace 'href="/documentation.html#', 'href="#'
    $content = $content -replace 'href="/', 'href="../'
    $content = $content -replace "href='/", "href='../"
    $content = $content -replace 'src="/', 'src="../'
    $content = $content -replace $findFile, $changeFile
    $content = $content -replace '//analytics.apache.org/', '/analytics.apache.org/' ## 404
    
    

    
    

    $changeFilePath = Join-Path -Path $targetDir -ChildPath $changeFile
    # 保存修改后的内容回文件
    $content | Set-Content -Path $changeFilePath -Encoding UTF8
    Write-Host "链接处理完成！ $changeFilePath" -ForegroundColor Green

    # 添加一个小延迟，避免对服务器发送过多请求
    Start-Sleep -Milliseconds 500
}

Write-Host "`n下载任务完成！" -ForegroundColor Green
Write-Host "总共处理了 $total 个文件。" -ForegroundColor Cyan