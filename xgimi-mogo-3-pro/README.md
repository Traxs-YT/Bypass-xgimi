# Nettoyer une XGIMI MoGo 3 Pro (Google TV 14)

Même démarche que sur le Halo+, adaptée à la MoGo 3 Pro (modèle G0035, appareil `altai`).
La liste vient de l'exemple testé sur un vrai appareil dans
[Gathin23/cleanyourtv](https://github.com/Gathin23/cleanyourtv) (`examples/xgimi-mogo-3-pro`, MIT),
avec les mêmes choix que sur le Halo+ : **Chromecast, télécommande téléphone et mises à jour firmware conservés**.

**13 paquets désactivés, rien de désinstallé** : démo magasin, outils d'usine, télémétrie,
préinstallations Google, écrans de veille, quelques applis XGIMI. Keystone, autofocus, HDMI,
MagiCast (recopie d'écran) et télécommande sont protégés : `disable.sh` refuse de les toucher.

## 1. Activer ADB sur le projecteur

1. Paramètres → Système → À propos → cliquez 7 fois sur **Build Android TV OS** (mode développeur).
2. Paramètres → Système → Options pour les développeurs → **Débogage sans fil** → *Associer avec un code*.
3. Sur le PC (avec [platform-tools](https://developer.android.com/tools/releases/platform-tools)) :
   ```sh
   adb pair <ip>:<port d'association>      # saisir le code affiché
   adb connect <ip>:<port affiché>
   adb tcpip 5555                          # port fixe pour la suite
   ```
   Le débogage sans fil se coupe à chaque reconnexion Wi-Fi : refaites ces étapes si besoin.

## 2. Vérifier puis appliquer

```sh
cd xgimi-mogo-3-pro
TV_HOST=<ip> DRY_RUN=1 ./disable.sh debloat.txt   # affiche ce qui serait fait
TV_HOST=<ip> ./disable.sh debloat.txt             # demande confirmation avant d'agir
adb reboot
```

Le script vérifie que l'appareil est bien `altai`, liste chaque paquet (absent / déjà désactivé /
à désactiver) et note ce qu'il a réellement désactivé dans `state/disabled.txt`.

Pour garder une appli, commentez sa ligne (`#`). Pour retirer aussi Chromecast, la télécommande
téléphone ou l'Assistant, décommentez-les dans la section « CONSERVÉS ».

## 3. Écran de veille

Ambient (Google) et Atmosphere (XGIMI) sont désactivés ; donnez-lui autre chose à afficher :
```sh
adb shell settings put secure screensaver_components com.android.dreams.basic/.Colors
```

## 4. Tester après deux redémarrages

Keystone auto, autofocus, HDMI 1 (via le menu Entrées), clé USB, télécommande (y compris les touches
YouTube/Netflix/Prime), recopie d'écran MagiCast.

## 5. Nouveau launcher (facultatif, comme sur le Halo+)

Sur Google TV les pubs viennent du launcher lui-même (`com.google.android.apps.tv.launcherx`) :
pour s'en débarrasser il faut un autre launcher. Le plus simple est de suivre le projet
cleanyourtv avec Claude Code (`PROMPT.md`), en lui indiquant `examples/xgimi-mogo-3-pro/debloat.txt`
et en gardant l'approbation manuelle de chaque commande. Particularités de ce modèle :

- Installer avec `HOME_KEY_SERVICE=1`, et dans la config du launcher :
  `"live_tv_package": ""`, `"settings_key_keycodes": [83]`,
  `"app_keys": ["KEYCODE_F4:com.google.android.youtube.tv", "KEYCODE_F9:com.netflix.ninja", "KEYCODE_F8:com.amazon.amazonvideo.livingroom"]`,
  `"stock_home_redirect": "com.google.android.apps.tv.launcherx"`.
- `com.xgimi.xrmservice` **réactive le launcher d'origine** à chaque touche XGIMI de la télécommande
  (bouton programmable, profil, power). Ne désactivez pas xrmservice ; ré-appliquez simplement la liste.
- HDMI 1 fonctionne via `com.google.android.tv.inputplayer`, pas besoin d'`input_action` (contrairement au Halo+).
- L'assistant de configuration (`setupwraith`) revendique HOME : décommentez-le dans la liste
  **uniquement après** avoir installé le nouveau launcher, et reconnectez le Wi-Fi s'il disparaît.
  Réactivez-le avant toute réinitialisation d'usine.

## En cas de problème

```sh
TV_HOST=<ip> ./restore.sh                     # réactive tout ce que disable.sh a désactivé
TV_HOST=<ip> ./restore.sh debloat.txt         # réactive toute la liste
TV_HOST=<ip> ./restore.sh "" com.google.android.apps.tv.launcherx   # + le launcher d'origine
adb reboot
```
Sans ADB, une réinitialisation d'usine réactive tout.
