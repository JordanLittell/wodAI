//
//  BodyMapArt.swift
//  wodAI
//
//  Body-map artwork as data: SVG path strings keyed by muscle slug.
//
//  ┌───────────────────────────────────────────────────────────────────────┐
//  │ PROVENANCE — PLACEHOLDER ART, NOT FOR RELEASE                         │
//  │                                                                       │
//  │ Author:  written by hand in this repo (no third-party source, no      │
//  │          traced reference) — so there is no licence to honour and     │
//  │          nothing to attribute.                                        │
//  │ Status:  deliberately low-fidelity blocked-out polygons. It is        │
//  │          positioned correctly but is obviously not finished art, so   │
//  │          it cannot be mistaken for the real figure and shipped by     │
//  │          accident.                                                    │
//  │ Replace: swap the two dictionaries below with the commissioned SVG's  │
//  │          path data and update this block with the illustrator, the    │
//  │          licence/assignment, and the date. Nothing else changes —     │
//  │          BodyMapView reads only this file.                            │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  Constraints the commissioned art must also satisfy (see the illustrator
//  spec): one closed path per region, ids matching `MuscleGroup.rawValue`,
//  regions must NOT overlap (overlapping fills double-darken and break the
//  intensity ramp), no strokes/gradients/filters, and front and back must share
//  one canvas and scale so the two figures align side by side.
//
//  Left/right pairs are two subpaths in a single path — a region is one unit as
//  far as intensity is concerned.
//

import CoreGraphics

enum BodyMapArt {

    /// Shared by both figures. Front and back MUST use the same viewBox.
    static let viewBox = CGSize(width: 100, height: 220)

    /// Neutral silhouette drawn under the regions: head plus body outline.
    static let outline = """
    M50,7 C56,7 60,11 60,17 C60,23 56,27 50,27 C44,27 40,23 40,17 C40,11 44,7 50,7 Z
    M40,28 L60,28 L74,34 L78,90 L70,92 L64,60 L63,100 L64,148 L62,188 L52,188 \
    L51,150 L49,150 L48,188 L38,188 L36,148 L37,100 L36,60 L30,92 L22,90 L26,34 Z
    """

    /// Front-facing regions. Anatomically front-only muscles (glutes,
    /// hamstrings, lats, triceps, mid/lower back) are absent by design — that
    /// asymmetry is why both figures are shown.
    static let front: [MuscleGroup: String] = [
        .traps:      "M36,30 L64,30 L61,40 L39,40 Z",
        .shoulders:  "M26,34 L36,32 L37,46 L27,45 Z M74,34 L64,32 L63,46 L73,45 Z",
        .chest:      "M38,41 L62,41 L61,56 L39,56 Z",
        .core:       "M41,57 L59,57 L57,88 L43,88 Z",
        .biceps:     "M25,47 L35,48 L34,66 L25,65 Z M75,47 L65,48 L66,66 L75,65 Z",
        .forearms:   "M25,67 L34,68 L32,90 L24,89 Z M75,67 L66,68 L68,90 L76,89 Z",
        .hipFlexors: "M42,89 L58,89 L60,100 L40,100 Z",
        .quads:      "M39,101 L49,101 L48,140 L38,139 Z M61,101 L51,101 L52,140 L62,139 Z",
        .calves:     "M39,150 L48,150 L47,182 L40,182 Z M61,150 L52,150 L53,182 L60,182 Z",
    ]

    /// Back-facing regions. Chest, biceps and hip flexors are absent by design.
    static let back: [MuscleGroup: String] = [
        .traps:      "M36,30 L64,30 L62,46 L38,46 Z",
        .shoulders:  "M26,34 L36,32 L37,46 L27,45 Z M74,34 L64,32 L63,46 L73,45 Z",
        .lats:       "M33,47 L43,47 L43,70 L35,67 Z M67,47 L57,47 L57,70 L65,67 Z",
        .back:       "M44,47 L56,47 L57,88 L43,88 Z",
        .triceps:    "M25,47 L35,48 L34,66 L25,65 Z M75,47 L65,48 L66,66 L75,65 Z",
        .forearms:   "M25,67 L34,68 L32,90 L24,89 Z M75,67 L66,68 L68,90 L76,89 Z",
        .glutes:     "M41,89 L49,89 L49,106 L39,104 Z M59,89 L51,89 L51,106 L61,104 Z",
        .hamstrings: "M39,107 L49,107 L48,146 L38,145 Z M61,107 L51,107 L52,146 L62,145 Z",
        .calves:     "M39,150 L48,150 L47,182 L40,182 Z M61,150 L52,150 L53,182 L60,182 Z",
    ]
}
