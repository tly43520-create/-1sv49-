; ==========================================================
; sde1D_param_dvs.cmd -- SWB quasi-1D, 3-Gaussian N side (HA, HA2, HA3). Swept params come from the SWB table;
; iter02 values: see sentaurus/iter02/iter02_params.csv. Fixed values are defined directly below.
; Output mesh: n<node>_msh.tdr, found by the sdevice tool through its Grid placeholder
; Geometry: width 1 um (x), depth Tepi+2 um (y, positive downward)
;   0 - Tepi       : Si epi (N- background Nepi) + P+ Gaussian + HA/HA2/HA3 phosphorus Gaussians
;   Tepi - Tepi+2  : Si sub (N+ 1e19, truncated)
; Contacts: Anode = top edge (y=0), Cathode = bottom edge (y=Tepi+2)
; ==========================================================

(sde:clear)
(sdegeo:set-auto-region-naming OFF)

; ---------------- parameters ----------------
(define Wdev   1.0)     ; device width [um]
(define Tepi   @Tepi@)   ; epi thickness [um]            iter02: 6.0
(define Tsub   2.0)     ; truncated substrate thickness [um]
(define Ytot   (+ Tepi Tsub))

(define Nepi   @Nepi@)   ; N- epi background [cm-3]      iter02-R: 1.5e14
(define Nsub   1e19)    ; N+ substrate [cm-3]

(define PPpeak 1e20)    ; P+ boron peak at surface [cm-3]
(define PPval  1e17)    ; P+ reference concentration ...
(define PPdep  @PPdep@)  ; depth where P+ = PPval [um]    0.297 (sigma 0.08)

(define HApeak @HApeak@) ; HA phosphorus peak [cm-3]      iter02-R: 7.3e16
(define HApos  @HApos@)  ; HA peak position [um]          iter02-R: 0.40
(define HAsig  @HAsig@)  ; HA standard deviation [um]     iter02-R: 0.063
(define HA2peak @HA2peak@) (define HA2pos @HA2pos@) (define HA2sig @HA2sig@)  ; R: 7.6e15/0.54/0.25; 1e10 = off
(define HA3peak @HA3peak@) (define HA3pos @HA3pos@) (define HA3sig @HA3sig@)  ; R: 1.0e15/0.88/0.80; 1e10 = off

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

(sdedr:define-gaussian-profile "Gauss.HA2" "PhosphorusActiveConcentration"
  "PeakPos" HA2pos "PeakVal" HA2peak "StdDev" HA2sig "Gauss" "Factor" 0.8)
(sdedr:define-analytical-profile-placement "Place.HA2" "Gauss.HA2" "BaseLine.Top"
  "Positive" "NoReplace" "Eval")

(sdedr:define-gaussian-profile "Gauss.HA3" "PhosphorusActiveConcentration"
  "PeakPos" HA3pos "PeakVal" HA3peak "StdDev" HA3sig "Gauss" "Factor" 0.8)
(sdedr:define-analytical-profile-placement "Place.HA3" "Gauss.HA3" "BaseLine.Top"
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

