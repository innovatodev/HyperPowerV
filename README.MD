# HyperPowerV by innovatodev

Créer, installer et configurer une machine virtuelle Hyper-V entièrement automatiquement (Windows client & server)

Le script injecte un fichier de réponse afin que l'installation soit automatique, il transforme l'iso pour utiliser le efi-noprompt afin de boot automatiquement sur cet ISO sans intervention utilisateur

Une fois configurée, la VM est lancée et le script attend que le Windows finisse de s'installer afin de le configurer à l'aide de powershell.
