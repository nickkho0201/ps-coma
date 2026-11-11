# Список доступных команд

## Активация Windows и Office

Команда загружает и сразу запускает [Microsoft Activation Scripts (MAS)](https://github.com/massgravel/Microsoft-Activation-Scripts) — сторонний инструмент для активации Windows и Microsoft Office. После запуска открывается интерактивное меню, в котором можно выбрать способ активации или открыть инструменты диагностики.

Запуск из PowerShell

```powershell
irm https://get.activated.win | iex
```

## Переключение параметра предупреждения RDP

[Toggle-RedirectionWarningDialogVersion.ps1](./Toggle-RedirectionWarningDialogVersion.ps1) проверяет параметр `RedirectionWarningDialogVersion` в разделе `HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services\Client`. Если параметра нет, скрипт создаёт его как `REG_DWORD` со значением `1`. Если параметр есть, скрипт предлагает подтвердить его удаление. При необходимости Windows запрашивает права администратора через UAC.

Запуск из PowerShell:

```powershell
irm https://raw.githubusercontent.com/nickkho0201/ps-coma/main/Toggle-RedirectionWarningDialogVersion.ps1 | iex
```
