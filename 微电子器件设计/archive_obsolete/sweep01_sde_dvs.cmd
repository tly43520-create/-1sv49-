; ==========================================================
; sde_dvs.cmd  -- SWB, sweep01 (quasi-1D). Swept params come from the SWB table;
; defaults = iter00 baseline. Fixed values are defined directly below.
; Output mesh: n<node>_msh.tdr, found by the sdevice tool through its Grid placeholder
; Geometry: width 1 um (x), depth 10 um (y, positive downward)
;   0 - 8 um  : Si epi   (N- background 3e14) + P+ Gaussian + N hyperabrupt Gaussian
;   8 - 10 um : Si sub   (N+ 1e19, truncated)
; Contacts: Anode = top edge (y=0), Cathode = bottom edge (y=10)
; ==========================================================

(sde:clear)
(sdegeo:set-auto-region-naming OFF)

; ---------------- parameters ----------------
(define Wdev   1.0)     ; device width [um]
(define Tepi   @Tepi@)   ; epi thickness [um]            default 8.0
(define Tsub   2.0)     ; truncated substrate thickness [um]
(define Ytot   (+ Tepi Tsub))

(define Nepi   @Nepi@)   ; N- epi background [cm-3]      default 3e14
(define Nsub   1e19)    ; N+ substrate [cm-3]

(define PPpeak 1e20)    ; P+ boron peak at surface [cm-3]
(define PPval  1e17)    ; P+ reference concentration ...
(define PPdep  @PPdep@)  ; depth where P+ = PPval [um]    default 0.297 (sigma 0.08)

(define HApeak @HApeak@) ; HA phosphorus peak [cm-3]      default 6e16
(define HApos  @HApos@)  ; HA peak position [um]          default 0.40
(define HAsig  @HAsig@)  ; HA standard deviation [um]     default 0.15

; ---------------- geometry ----------------
(sdegeo:create-rectangle (position 0 0 0)    (position Wdev Tepi 0) "Silicon" "region_Epi")
(sdegeo:create-rectangle (position 0 Tepi 0) (position Wdev Ytot 0) "Silicon" "region_Sub")

; ---------------- contacts ----------------
(sdegeo:define-contact-set "Anode"   4 (color:rgb 1 0 0) "##")
(sdegeo:define-contact-set "Cathode" 4 (color:rgb 0 1 0) "##")

(sdegeo:set-current-contact-set "Anode")
(sdegeo:set-contact (list (car (find-edge-id (position (/ Wdev 2) 0 0)))) "Anode")

(sdegeo:set-current-contact-set "Cathode")
(sdegeo:set-contact (list (car (find-edge-id (position (/ Wdev 2) Ytot 0)))) "Cathode")

; ---------------- constant doping ----------------
(sdedr:define-constant-profile "Const.Epi" "PhosphorusActiveConcentration" Nepi)
(sdedr:define-constant-profile-region "Place.Epi" "Const.Epi" "region_Epi")

(sdedr:define-constant-profile "Const.Sub" "PhosphorusActiveConcentration" Nsub)
(sdedr:define-constant-profile-region "Place.Sub" "Const.Sub" "region_Sub")

; ---------------- analytical doping (baseline = top surface) ----------------
(sdedr:define-refeval-window "BaseLine.Top" "Line" (position 0 0 0) (position Wdev 0 0))

; P+ anode: boron Gaussian, peak at surface
(sdedr:define-gaussian-profile "Gauss.PP" "BoronActiveConcentration"
  "PeakPos" 0 "PeakVal" PPpeak "ValueAtDepth" PPval "Depth" PPdep "Gauss" "Factor" 0.8)
(sdedr:define-analytical-profile-placement "Place.PP" "Gauss.PP" "BaseLine.Top"
  "Positive" "NoReplace" "Eval")

; N hyperabrupt layer: PHOSPHORUS Gaussian (was Boron in the console session)
(sdedr:define-gaussian-profile "Gauss.HA" "PhosphorusActiveConcentration"
  "PeakPos" HApos "PeakVal" HApeak "StdDev" HAsig "Gauss" "Factor" 0.8)
(sdedr:define-analytical-profile-placement "Place.HA" "Gauss.HA" "BaseLine.Top"
  "Positive" "NoReplace" "Eval")

; ---------------- mesh refinement ----------------
; args: name  maxX maxY minX minY   (x kept coarse: quasi-1D, nothing varies along x)
(sdedr:define-refeval-window "Win.Top"  "Rectangle" (position -0.5 -0.5 0) (position (+ Wdev 0.5) 1 0))
(sdedr:define-refeval-window "Win.Rest" "Rectangle" (position -0.5 1 0)    (position (+ Wdev 0.5) (+ Ytot 1) 0))

(sdedr:define-refinement-size "Ref.Top" 0.5 0.005 0.1 0.001)
(sdedr:define-refinement-function "Ref.Top" "DopingConcentration" "MaxTransDiff" 1)
(sdedr:define-refinement-placement "RefPlace.Top" "Ref.Top" (list "window" "Win.Top"))

(sdedr:define-refinement-size "Ref.Rest" 0.5 0.1 0.1 0.05)
(sdedr:define-refinement-function "Ref.Rest" "DopingConcentration" "MaxTransDiff" 1)
(sdedr:define-refinement-placement "RefPlace.Rest" "Ref.Rest" (list "window" "Win.Rest"))

; ---------------- save & mesh ----------------
(sde:save-model "n@node@")
(sde:set-meshing-command "snmesh")
(sde:build-mesh "" "n@node@")

