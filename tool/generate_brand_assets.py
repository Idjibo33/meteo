#!/usr/bin/env python3
"""Génère les icônes de marque à toutes les tailles requises par les plateformes.

La marque est volontairement géométrique : un disque (le soleil) au-dessus de
deux traits (l'horizon), dans le seul accent de l'application. Le dessin est
fait en Python pour rester parfaitement reproductible et net à toute taille ;
`assets/brand/logo.svg` en est la source vectorielle équivalente.

Usage : python3 tool/generate_brand_assets.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

RACINE = Path(__file__).resolve().parent.parent
ACCENT = (0x26, 0xA6, 0x9A, 0xFF)
FOND = (0x00, 0x00, 0x00, 0xFF)
TRANSPARENT = (0, 0, 0, 0)
SUR_ECHANTILLONNAGE = 4


def _disque(draw: ImageDraw.ImageDraw, s: int, couleur: tuple[int, ...]) -> None:
    draw.ellipse(
        (0.33 * s, 0.25 * s, 0.67 * s, 0.59 * s),
        fill=couleur,
    )


def _horizon(draw: ImageDraw.ImageDraw, s: int, couleur: tuple[int, ...]) -> None:
    draw.rounded_rectangle(
        (0.235 * s, 0.64 * s, 0.765 * s, 0.695 * s),
        radius=0.0275 * s,
        fill=couleur,
    )
    draw.rounded_rectangle(
        (0.32 * s, 0.755 * s, 0.68 * s, 0.802 * s),
        radius=0.0235 * s,
        fill=couleur,
    )


def _marque(taille: int, couleur=ACCENT) -> Image.Image:
    """La marque seule, sur fond transparent."""
    s = taille * SUR_ECHANTILLONNAGE
    image = Image.new("RGBA", (s, s), TRANSPARENT)
    draw = ImageDraw.Draw(image)
    _disque(draw, s, couleur)
    _horizon(draw, s, couleur)
    return image.resize((taille, taille), Image.Resampling.LANCZOS)


def _fond(taille: int, arrondi: bool) -> Image.Image:
    s = taille * SUR_ECHANTILLONNAGE
    image = Image.new("RGBA", (s, s), TRANSPARENT)
    draw = ImageDraw.Draw(image)
    if arrondi:
        draw.rounded_rectangle((0, 0, s, s), radius=0.22 * s, fill=FOND)
    else:
        draw.rectangle((0, 0, s, s), fill=FOND)
    return image.resize((taille, taille), Image.Resampling.LANCZOS)


def icone(taille: int, *, arrondi: bool = True, echelle: float = 1.0) -> Image.Image:
    """Marque centrée sur fond noir, avec une marge optionnelle (maskable)."""
    image = _fond(taille, arrondi=arrondi)
    if echelle != 1.0:
        marque = _marque(round(taille * echelle))
        coin = (taille - marque.width) // 2
        image.alpha_composite(marque, (coin, coin))
    else:
        marque = _marque(taille)
        image.alpha_composite(marque)
    return image.convert("RGBA")


def premier_plan_adaptatif(taille: int) -> Image.Image:
    """Android 12+ : la zone visible est un cercle de 66 dp sur une grille de 108 dp."""
    image = Image.new("RGBA", (taille, taille), TRANSPARENT)
    marque = _marque(round(taille * 0.62))
    coin = (taille - marque.width) // 2
    image.alpha_composite(marque, (coin, coin))
    return image


def ecrire(image: Image.Image, chemin: str) -> None:
    destination = RACINE / chemin
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination)
    print(f"{chemin} ({image.width}x{image.height})")


def main() -> None:
    ecrire(icone(512), "assets/brand/logo-512.png")
    ecrire(_marque(512), "assets/brand/mark-512.png")
    # Splash HTML : servi avant le bootstrap Flutter, donc hors du bundle Dart.
    ecrire(_marque(512), "web/brand/mark-512.png")

    # Android : icônes héritées + premier plan adaptatif + image de splash.
    dinites = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for densite, taille in dinites.items():
        ecrire(
            icone(taille),
            f"android/app/src/main/res/mipmap-{densite}/ic_launcher.png",
        )
        ecrire(
            premier_plan_adaptatif(round(taille * 108 / 48)),
            f"android/app/src/main/res/mipmap-{densite}/ic_launcher_foreground.png",
        )
    ecrire(_marque(512), "android/app/src/main/res/drawable-nodpi/launch_image.png")

    # iOS : l'OS applique lui-même le masque arrondi.
    appicons = RACINE / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for chemin in sorted(appicons.glob("Icon-*.png")):
        taille = Image.open(chemin).width
        ecrire(icone(taille, arrondi=False), str(chemin.relative_to(RACINE)))
    for chemin in sorted(
        (RACINE / "ios/Runner/Assets.xcassets/LaunchImage.imageset").glob("*.png")
    ):
        ecrire(_marque(512), str(chemin.relative_to(RACINE)))

    # Web : favicon, icônes PWA et variantes maskable.
    ecrire(icone(32), "web/favicon.png")
    for taille in (192, 512):
        ecrire(icone(taille, arrondi=False), f"web/icons/Icon-{taille}.png")
        ecrire(
            icone(taille, arrondi=False, echelle=0.72),
            f"web/icons/Icon-maskable-{taille}.png",
        )

    # Windows : ICO multi-tailles.
    tailles_ico = [16, 24, 32, 48, 64, 128, 256]
    images = [icone(t) for t in tailles_ico]
    destination = RACINE / "windows/runner/resources/app_icon.ico"
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Pillow réduit l'image la plus grande pour produire chaque entrée.
    images[-1].save(
        destination,
        format="ICO",
        sizes=[(t, t) for t in tailles_ico],
    )
    print(f"windows/runner/resources/app_icon.ico ({', '.join(map(str, tailles_ico))})")

    # Linux : icône installée dans le bundle et utilisée comme icône de fenêtre.
    ecrire(icone(512), "linux/runner/resources/meteo.png")


if __name__ == "__main__":
    main()
