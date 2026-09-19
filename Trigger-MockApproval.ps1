$pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", "LocalLoop_ControlPipe", [System.IO.Pipes.PipeDirection]::InOut, [System.IO.Pipes.PipeOptions]::Asynchronous)
try {
    Write-Host "Connecting to LocalLoop_ControlPipe..."
    $pipe.Connect(2000)
    Write-Host "Connected!"

    $writer = New-Object System.IO.StreamWriter($pipe)
    $writer.AutoFlush = $true
    
    $intentId = [guid]::NewGuid().ToString()
    $intent = @{
        IntentId = $intentId
        DeviceId = "MockDevice"
        Action = "install"
        Target = "npm packages"
        WorkingDirectory = "E:\Ghost-Link"
        Command = "npm install express cors"
        Reasoning = "Adding express for the backend API"
        RiskLevel = "Medium"
        Timestamp = (Get-Date).ToString("o")
    }

    $msg = @{
        type = "command_request"
        data = ($intent | ConvertTo-Json -Compress)
        correlationId = "mock-123"
    }

    $jsonMsg = $msg | ConvertTo-Json -Compress
    Write-Host "Sending: $jsonMsg"
    $writer.WriteLine($jsonMsg)
    
    Write-Host "Sent Mock Approval! Check the mobile app."
    Start-Sleep -Seconds 2
} catch {
    Write-Host "Error: $_"
} finally {
    $pipe.Dispose()
}
