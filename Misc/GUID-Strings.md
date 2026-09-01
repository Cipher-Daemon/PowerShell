# GUID Strings

```powershell
[guid]::NewGuid().ToString()
```

```powershell
(New-Guid).Guid.ToUpper()
# Output: D3B07384-D113-4956-A5CC-9811D279CF44
```

## `.ToString()` Format Specifier

|Specifier|Description|Example|
|--|--|--|
|"D"|Default|d3b07384-d113-4956-a5cc-9811d279cf44|
|"N"|No Hyphens|d3b07384d1134956a5cc9811d279cf44|
|"B"|Enclosed in curly brackets|{d3b07384-d113-4956-a5cc-9811d279cf44}|
|"p"|Enclosed in parantheses|(d3b07384-d113-4956-a5cc-9811d279cf44)|

Example:

```powershell
[guid]::NewGuid().ToString("D")
# Output: d3b07384-d113-4956-a5cc-9811d279cf44
```
