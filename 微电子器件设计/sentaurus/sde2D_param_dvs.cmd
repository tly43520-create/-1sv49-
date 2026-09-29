; ==========================================================
; sde2D_param_dvs.cmd -- 2D planar hyperabrupt varactor, doping AND window width (@Wwin@) from SWB table
; Same parameter names as the quasi-1D script (up to 3 phosphorus Gaussians).
; y positive downward, units um. Output mesh: n<node>_msh.tdr
; ==========================================================

(sde:clear)
(sdegeo:set-auto-region-naming OFF)

; ---------------- parameters ----------------
(define Wwin  @Wwin@) ; P+ window width [um]: 20 (as iter00-2D) and 40 for the area/edge split
(define Xw1    5.0)   ; window left edge (5 um oxide-covered margin on each side, unchanged)
(define Xw2   (+ Xw1 Wwin)) ; window right edge
(define Wtot  (+ Xw2 5.0))  ; total width (Wwin 20 -> 30 um, exactly the iter00-2D geometry)
(define Tox    0.5)   ; passivation oxide thickness
(define Tepi   @Tepi@) ; epi thickness
(define Ytot  (+ Tepi 2.0)) ; bottom of truncated substrate (2 um N+)

(define Nsub   1e19)
(define PPpeak 1e20)  (define PPval 1e17)

; ---- swept / design parameters (SWB table) ----
(define Nepi    @Nepi@)
(define PPdep   @PPdep@)
(define HApeak  @HApeak@)   (define HApos  @HApos@)   (define HAsig  @HAsig@)
(define HA2peak @HA2peak@)  (define HA2pos @HA2pos@)  (define HA2sig @HA2sig@)
(define HA3peak @HA3peak@)  (define HA3pos @HA3pos@)  (define HA3sig @HA3sig@)
; set HA2peak / HA3peak = 1e10 to switch a layer off

; ---------------- geometry ----------------
(sdegeo:create-rectangle (position 0   0 0) (position Xw1  (- Tox) 0) "Oxide" "region_oxide1")
(sdegeo:create-rectangle (position Xw2 0 0) (position Wtot (- Tox) 0) "Oxide" "region_oxide2")
(sdegeo:create-rectangle (position 0 0 0)    (position Wtot Tepi 0) "Silicon" "region_Epi")
(sdegeo:create-rectangle (position 0 Tepi 0) (position Wtot Ytot 0) "Silicon" "region_Sub")

; ---------------- contacts (edges recorded from GUI journal) ----------------
(sdegeo:define-contact-set "Anode"   4 (color:rgb 1 0 0) "##")
(sdegeo:define-contact-set "Cathode" 4 (color:rgb 0 1 0) "##")
(sdegeo:set-current-contact-set "Anode")
(sdegeo:set-contact (list (car (find-edge-id (position (/ Wtot 2) 0 0)))) "Anode")
(sdegeo:set-current-contact-set "Cathode")
(sdegeo:set-contact (list (car (find-edge-id (position (/ Wtot 2) Ytot 0)))) "Cathode")

; ---------------- constant doping ----------------
(sdedr:define-constant-profile "Const.Epi" "PhosphorusActiveConcentration" Nepi)
(sdedr:define-constant-profile-region "Place.Epi" "Const.Epi" "region_Epi")
(sdedr:define-constant-profile "Const.Sub" "PhosphorusActiveConcentration" Nsub)
(sdedr:define-constant-profile-region "Place.Sub" "Const.Sub" "region_Sub")

; ---------------- analytical doping ----------------
; P+ : window only
(sdedr:define-refeval-window "BaseLine.Window" "Line" (position Xw1 0 0) (position Xw2 0 0))
(sdedr:define-gaussian-profile "Gauss.PP" "BoronActiveConcentration"
  "PeakPos" 0 "PeakVal" PPpeak "ValueAtDepth" PPval "Depth" PPdep "Gauss" "Factor" 0.8)
(sdedr:define-analytical-profile-placement "Place.PP" "Gauss.PP" "BaseLine.Window"
  "Positive" "NoReplace" "Eval")

; N hyperabrupt : full width (spec). For the "window-only" variant,
; replace "BaseLine.Full" with "BaseLine.Window" in Place.HA.
(sdedr:define-refeval-window "BaseLine.Full" "Line" (position 0 0 0) (position Wtot 0 0))
(sdedr:define-gaussian-profile "Gauss.HA" "PhosphorusActiveConcentration"
  "PeakPos" HApos "PeakVal" HApeak "StdDev" HAsig "Gauss" "Factor" 0.8)
(sdedr:define-analytical-profile-placement "Place.HA" "Gauss.HA" "BaseLine.Full"
  "Positive" "NoReplace" "Eval")

; 2nd and 3rd N layers (same baseline as the first one)
(sdedr:define-gaussian-profile "Gauss.HA2" "PhosphorusActiveConcentration"
  "PeakPos" HA2pos "PeakVal" HA2peak "StdDev" HA2sig "Gauss" "Factor" 0.8)
(sdedr:define-analytical-profile-placement "Place.HA2" "Gauss.HA2" "BaseLine.Full"
  "Positive" "NoReplace" "Eval")
(sdedr:define-gaussian-profile "Gauss.HA3" "PhosphorusActiveConcentration"
  "PeakPos" HA3pos "PeakVal" HA3peak "StdDev" HA3sig "Gauss" "Factor" 0.8)
(sdedr:define-analytical-profile-placement "Place.HA3" "Gauss.HA3" "BaseLine.Full"
  "Positive" "NoReplace" "Eval")

; ---------------- mesh refinement ----------------
; size args: name maxX maxY minX minY

; 1 background
(sdedr:define-refeval-window "Win.All" "Rectangle" (position -0.5 -1.0 0) (position (+ Wtot 0.5) (+ Ytot 0.5) 0))
(sdedr:define-refinement-size "Ref.All" 1.0 0.5 0.1 0.05)
(sdedr:define-refinement-function "Ref.All" "DopingConcentration" "MaxTransDiff" 1)
(sdedr:define-refinement-placement "RP.All" "Ref.All" (list "window" "Win.All"))

; 2 top junction zone, full width
(sdedr:define-refeval-window "Win.Top" "Rectangle" (position 0 -0.1 0) (position Wtot 1.0 0))
(sdedr:define-refinement-size "Ref.Top" 1.0 0.01 0.1 0.005)
(sdedr:define-refinement-function "Ref.Top" "DopingConcentration" "MaxTransDiff" 1)
(sdedr:define-refinement-placement "RP.Top" "Ref.Top" (list "window" "Win.Top"))

; 3 P+ corners
(sdedr:define-refeval-window "Win.CornerL" "Rectangle" (position (- Xw1 1) -0.1 0) (position (+ Xw1 1) 1.2 0))
(sdedr:define-refeval-window "Win.CornerR" "Rectangle" (position (- Xw2 1) -0.1 0) (position (+ Xw2 1) 1.2 0))
(sdedr:define-refinement-size "Ref.Corner" 0.02 0.02 0.02 0.02)
(sdedr:define-refinement-function "Ref.Corner" "DopingConcentration" "MaxTransDiff" 1)
(sdedr:define-refinement-placement "RP.CornerL" "Ref.Corner" (list "window" "Win.CornerL"))
(sdedr:define-refinement-placement "RP.CornerR" "Ref.Corner" (list "window" "Win.CornerR"))

; 4 lateral depletion under oxide
(sdedr:define-refeval-window "Win.SideL" "Rectangle" (position 0 0 0) (position (+ Xw1 2) Tepi 0))
(sdedr:define-refeval-window "Win.SideR" "Rectangle" (position (- Xw2 2) 0 0) (position Wtot Tepi 0))
(sdedr:define-refinement-size "Ref.Side" 0.2 0.2 0.05 0.05)
(sdedr:define-refinement-placement "RP.SideL" "Ref.Side" (list "window" "Win.SideL"))
(sdedr:define-refinement-placement "RP.SideR" "Ref.Side" (list "window" "Win.SideR"))

; 5 vertical depletion sweep zone
(sdedr:define-refeval-window "Win.Sweep" "Rectangle" (position 0 1.0 0) (position Wtot Tepi 0))
(sdedr:define-refinement-size "Ref.Sweep" 1.0 0.1 0.1 0.02)
(sdedr:define-refinement-placement "RP.Sweep" "Ref.Sweep" (list "window" "Win.Sweep"))

; ---------------- save & mesh ----------------
(sde:save-model "n@node@")
(sde:set-meshing-command "snmesh")
(sde:build-mesh "" "n@node@")
