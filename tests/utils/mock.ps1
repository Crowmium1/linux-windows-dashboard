$global:attempt = 0
function Test-Connection {
    if ($global:attempt -lt 2) {
        $global:attempt++
        throw "Connection failed"
    }
    return $true
}
