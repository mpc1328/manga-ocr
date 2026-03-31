# Manga OCR — Traduttore Manga EN→IT in tempo reale

App iOS nativa che usa la fotocamera del tuo iPhone per riconoscere il testo dei manga in inglese e tradurlo istantaneamente in italiano, con overlay direttamente sullo schermo.

## Funzionalità

- 📷 **Camera in tempo reale** — inquadra una pagina di manga e il testo viene riconosciuto automaticamente
- 🔤 **OCR con Apple Vision** — riconoscimento testo accurato integrato nel sistema
- 🇮🇹 **Traduzione EN→IT** — traduzione automatica inglese→italiano
  - iOS 18+: usa il framework Translation di Apple (on-device, nessuna connessione necessaria)
  - iOS 17: fallback su API MyMemory (richiede connessione internet)
- 🎯 **Overlay visivo** — il testo tradotto appare sovrapposto alla posizione originale
- ⏸️ **Pausa/Riprendi** — puoi mettere in pausa la scansione per leggere con calma

## Requisiti

- **iPhone** con iOS 17.0+
- **Xcode 15.4+** su un Mac per compilare
- Account Apple Developer (anche gratuito per test su device personale)

## Come compilare e installare

### Opzione 1: Con un Mac

1. Copia la cartella `OCR` su un Mac
2. Apri `MangaOCR.xcodeproj` con Xcode
3. In Xcode → Signing & Capabilities → seleziona il tuo Team (Apple ID)
4. Collega il tuo iPhone via cavo USB
5. Seleziona il tuo iPhone come destinazione in alto
6. Premi ▶️ (Run) per compilare e installare

### Opzione 2: Senza un Mac (servizi cloud)

Se non hai un Mac, puoi usare:
- **MacStadium** o **AWS EC2 Mac** — Mac in cloud
- **Codemagic** / **Bitrise** — CI/CD per iOS che builds e firma l'app

## Struttura del progetto

```
MangaOCR/
├── MangaOCRApp.swift          # Entry point dell'app
├── ContentView.swift           # UI principale con camera + overlay
├── Info.plist                  # Permessi (camera)
├── Assets.xcassets/            # Icone e colori
├── Camera/
│   ├── CameraManager.swift     # Gestione AVCaptureSession
│   └── CameraPreviewView.swift # Preview camera in SwiftUI
├── Models/
│   └── RecognizedTextBlock.swift # Modello dati testo riconosciuto
├── OCR/
│   └── OCRProcessor.swift      # Riconoscimento testo con Vision
├── Translation/
│   └── TranslationService.swift # Traduzione EN→IT
├── ViewModels/
│   └── MangaOCRViewModel.swift  # ViewModel principale
└── Views/
    └── TextOverlayView.swift    # Overlay testo tradotto
```

## Come funziona

1. La **fotocamera** cattura frame video in tempo reale
2. Ogni ~0.4 secondi un frame viene inviato al **Vision framework** per OCR
3. Il testo riconosciuto viene passato al **servizio di traduzione**
4. Il testo tradotto viene mostrato in **overlay** sulla posizione originale del testo

## Note

- L'OCR funziona meglio con manga a buona risoluzione e testo chiaro
- La prima traduzione potrebbe essere più lenta (download del modello di traduzione su iOS 18)
- Per risultati migliori, tieni il telefono fermo e vicino alla pagina
