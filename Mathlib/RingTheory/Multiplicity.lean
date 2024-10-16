/-
Copyright (c) 2018 Robert Y. Lewis. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Robert Y. Lewis, Chris Hughes
-/
import Mathlib.Algebra.Associated.Basic
import Mathlib.Algebra.BigOperators.Group.Finset
import Mathlib.Algebra.SMulWithZero
import Mathlib.Data.Nat.PartENat
import Mathlib.Tactic.Linarith

/-!
# Multiplicity of a divisor

For a commutative monoid, this file introduces the notion of multiplicity of a divisor and proves
several basic results on it.

## Main definitions

* `multiplicity a b`: for two elements `a` and `b` of a commutative monoid returns the largest
  number `n` such that `a ^ n ∣ b` or infinity, written `⊤`, if `a ^ n ∣ b` for all natural numbers
  `n`.
* `multiplicity.Finite a b`: a predicate denoting that the multiplicity of `a` in `b` is finite.
-/


variable {α β : Type*}

open Nat Part

/-- `multiplicity a b` returns the largest natural number `n` such that
  `a ^ n ∣ b`, as a `PartENat` or natural with infinity. If `∀ n, a ^ n ∣ b`,
  then it returns `⊤`-/
def multiplicity [Monoid α] [DecidableRel ((· ∣ ·) : α → α → Prop)] (a b : α) : PartENat :=
  PartENat.find fun n => ¬a ^ (n + 1) ∣ b

namespace multiplicity

section Monoid

variable [Monoid α] [Monoid β]

/-- `multiplicity.Finite a b` indicates that the multiplicity of `a` in `b` is finite. -/
abbrev Finite (a b : α) : Prop :=
  ∃ n : ℕ, ¬a ^ (n + 1) ∣ b

theorem finite_iff_dom [DecidableRel ((· ∣ ·) : α → α → Prop)] {a b : α} :
    Finite a b ↔ (multiplicity a b).Dom :=
  Iff.rfl

theorem finite_def {a b : α} : Finite a b ↔ ∃ n : ℕ, ¬a ^ (n + 1) ∣ b :=
  Iff.rfl

theorem not_dvd_one_of_finite_one_right {a : α} : Finite a 1 → ¬a ∣ 1 := fun ⟨n, hn⟩ ⟨d, hd⟩ =>
  hn ⟨d ^ (n + 1), (pow_mul_pow_eq_one (n + 1) hd.symm).symm⟩

@[norm_cast]
theorem Int.natCast_multiplicity (a b : ℕ) : multiplicity (a : ℤ) (b : ℤ) = multiplicity a b := by
  apply Part.ext'
  · rw [← @finite_iff_dom ℕ, @finite_def ℕ, ← @finite_iff_dom ℤ, @finite_def ℤ]
    norm_cast
  · intro h1 h2
    apply _root_.le_antisymm <;>
      · apply Nat.find_mono
        norm_cast
        simp

@[deprecated (since := "2024-04-05")] alias Int.coe_nat_multiplicity := Int.natCast_multiplicity

theorem not_finite_iff_forall {a b : α} : ¬Finite a b ↔ ∀ n : ℕ, a ^ n ∣ b :=
  ⟨fun h n =>
    Nat.casesOn n
      (by
        rw [_root_.pow_zero]
        exact one_dvd _)
      (by simpa [Finite, Classical.not_not] using h),
    by simp [Finite, multiplicity, Classical.not_not]; tauto⟩

theorem not_unit_of_finite {a b : α} (h : Finite a b) : ¬IsUnit a :=
  let ⟨n, hn⟩ := h
  hn ∘ IsUnit.dvd ∘ IsUnit.pow (n + 1)

theorem finite_of_finite_mul_right {a b c : α} : Finite a (b * c) → Finite a b := fun ⟨n, hn⟩ =>
  ⟨n, fun h => hn (h.trans (dvd_mul_right _ _))⟩

variable [DecidableRel ((· ∣ ·) : α → α → Prop)] [DecidableRel ((· ∣ ·) : β → β → Prop)]

theorem pow_dvd_of_le_multiplicity {a b : α} {k : ℕ} :
    (k : PartENat) ≤ multiplicity a b → a ^ k ∣ b := by
  rw [← PartENat.some_eq_natCast]
  exact
    Nat.casesOn k
      (fun _ => by
        rw [_root_.pow_zero]
        exact one_dvd _)
      fun k ⟨_, h₂⟩ => by_contradiction fun hk => Nat.find_min _ (lt_of_succ_le (h₂ ⟨k, hk⟩)) hk

theorem pow_multiplicity_dvd {a b : α} (h : Finite a b) : a ^ get (multiplicity a b) h ∣ b :=
  pow_dvd_of_le_multiplicity (by rw [PartENat.natCast_get])

theorem is_greatest {a b : α} {m : ℕ} (hm : multiplicity a b < m) : ¬a ^ m ∣ b := fun h => by
  rw [PartENat.lt_coe_iff] at hm; exact Nat.find_spec hm.fst ((pow_dvd_pow _ hm.snd).trans h)

theorem is_greatest' {a b : α} {m : ℕ} (h : Finite a b) (hm : get (multiplicity a b) h < m) :
    ¬a ^ m ∣ b :=
  is_greatest (by rwa [← PartENat.coe_lt_coe, PartENat.natCast_get] at hm)

theorem pos_of_dvd {a b : α} (hfin : Finite a b) (hdiv : a ∣ b) :
    0 < (multiplicity a b).get hfin := by
  refine zero_lt_iff.2 fun h => ?_
  simpa [hdiv] using is_greatest' hfin (lt_one_iff.mpr h)

theorem unique {a b : α} {k : ℕ} (hk : a ^ k ∣ b) (hsucc : ¬a ^ (k + 1) ∣ b) :
    (k : PartENat) = multiplicity a b :=
  le_antisymm (le_of_not_gt fun hk' => is_greatest hk' hk) <| by
    have : Finite a b := ⟨k, hsucc⟩
    rw [PartENat.le_coe_iff]
    exact ⟨this, Nat.find_min' _ hsucc⟩

theorem unique' {a b : α} {k : ℕ} (hk : a ^ k ∣ b) (hsucc : ¬a ^ (k + 1) ∣ b) :
    k = get (multiplicity a b) ⟨k, hsucc⟩ := by
  rw [← PartENat.natCast_inj, PartENat.natCast_get, unique hk hsucc]

theorem le_multiplicity_of_pow_dvd {a b : α} {k : ℕ} (hk : a ^ k ∣ b) :
    (k : PartENat) ≤ multiplicity a b :=
  le_of_not_gt fun hk' => is_greatest hk' hk

theorem pow_dvd_iff_le_multiplicity {a b : α} {k : ℕ} :
    a ^ k ∣ b ↔ (k : PartENat) ≤ multiplicity a b :=
  ⟨le_multiplicity_of_pow_dvd, pow_dvd_of_le_multiplicity⟩

theorem multiplicity_lt_iff_not_dvd {a b : α} {k : ℕ} :
    multiplicity a b < (k : PartENat) ↔ ¬a ^ k ∣ b := by rw [pow_dvd_iff_le_multiplicity, not_le]

theorem eq_coe_iff {a b : α} {n : ℕ} :
    multiplicity a b = (n : PartENat) ↔ a ^ n ∣ b ∧ ¬a ^ (n + 1) ∣ b := by
  rw [← PartENat.some_eq_natCast]
  exact
    ⟨fun h =>
      let ⟨h₁, h₂⟩ := eq_some_iff.1 h
      h₂ ▸ ⟨pow_multiplicity_dvd _, is_greatest (by
              rw [PartENat.lt_coe_iff]
              exact ⟨h₁, lt_succ_self _⟩)⟩,
      fun h => eq_some_iff.2 ⟨⟨n, h.2⟩, Eq.symm <| unique' h.1 h.2⟩⟩

theorem eq_top_iff {a b : α} : multiplicity a b = ⊤ ↔ ∀ n : ℕ, a ^ n ∣ b :=
  (PartENat.find_eq_top_iff _).trans <| by
    simp only [Classical.not_not]
    exact
      ⟨fun h n =>
        Nat.casesOn n
          (by
            rw [_root_.pow_zero]
            exact one_dvd _)
          fun n => h _,
        fun h n => h _⟩

@[simp]
theorem isUnit_left {a : α} (b : α) (ha : IsUnit a) : multiplicity a b = ⊤ :=
  eq_top_iff.2 fun _ => IsUnit.dvd (ha.pow _)

-- @[simp] Porting note (#10618): simp can prove this
theorem one_left (b : α) : multiplicity 1 b = ⊤ :=
  isUnit_left b isUnit_one

@[simp]
theorem get_one_right {a : α} (ha : Finite a 1) : get (multiplicity a 1) ha = 0 := by
  rw [PartENat.get_eq_iff_eq_coe, eq_coe_iff, _root_.pow_zero]
  simp [not_dvd_one_of_finite_one_right ha]

-- @[simp] Porting note (#10618): simp can prove this
theorem unit_left (a : α) (u : αˣ) : multiplicity (u : α) a = ⊤ :=
  isUnit_left a u.isUnit

theorem multiplicity_eq_zero {a b : α} : multiplicity a b = 0 ↔ ¬a ∣ b := by
  rw [← Nat.cast_zero, eq_coe_iff]
  simp only [_root_.pow_zero, isUnit_one, IsUnit.dvd, zero_add, pow_one, true_and]

theorem multiplicity_ne_zero {a b : α} : multiplicity a b ≠ 0 ↔ a ∣ b :=
  multiplicity_eq_zero.not_left

theorem eq_top_iff_not_finite {a b : α} : multiplicity a b = ⊤ ↔ ¬Finite a b :=
  Part.eq_none_iff'

theorem ne_top_iff_finite {a b : α} : multiplicity a b ≠ ⊤ ↔ Finite a b := by
  rw [Ne, eq_top_iff_not_finite, Classical.not_not]

theorem lt_top_iff_finite {a b : α} : multiplicity a b < ⊤ ↔ Finite a b := by
  rw [lt_top_iff_ne_top, ne_top_iff_finite]

theorem exists_eq_pow_mul_and_not_dvd {a b : α} (hfin : Finite a b) :
    ∃ c : α, b = a ^ (multiplicity a b).get hfin * c ∧ ¬a ∣ c := by
  obtain ⟨c, hc⟩ := multiplicity.pow_multiplicity_dvd hfin
  refine ⟨c, hc, ?_⟩
  rintro ⟨k, hk⟩
  rw [hk, ← mul_assoc, ← _root_.pow_succ] at hc
  have h₁ : a ^ ((multiplicity a b).get hfin + 1) ∣ b := ⟨k, hc⟩
  exact (multiplicity.eq_coe_iff.1 (by simp)).2 h₁

theorem multiplicity_le_multiplicity_iff {a b : α} {c d : β} :
    multiplicity a b ≤ multiplicity c d ↔ ∀ n : ℕ, a ^ n ∣ b → c ^ n ∣ d :=
  ⟨fun h _ hab => pow_dvd_of_le_multiplicity (le_trans (le_multiplicity_of_pow_dvd hab) h), fun h =>
    letI := Classical.dec (Finite a b)
    if hab : Finite a b then by
      rw [← PartENat.natCast_get (finite_iff_dom.1 hab)]
      exact le_multiplicity_of_pow_dvd (h _ (pow_multiplicity_dvd _))
    else by
      have : ∀ n : ℕ, c ^ n ∣ d := fun n => h n (not_finite_iff_forall.1 hab _)
      rw [eq_top_iff_not_finite.2 hab, eq_top_iff_not_finite.2 (not_finite_iff_forall.2 this)]⟩

theorem multiplicity_eq_multiplicity_iff {a b : α} {c d : β} :
    multiplicity a b = multiplicity c d ↔ ∀ n : ℕ, a ^ n ∣ b ↔ c ^ n ∣ d :=
  ⟨fun h n =>
    ⟨multiplicity_le_multiplicity_iff.mp h.le n, multiplicity_le_multiplicity_iff.mp h.ge n⟩,
    fun h =>
    le_antisymm (multiplicity_le_multiplicity_iff.mpr fun n => (h n).mp)
      (multiplicity_le_multiplicity_iff.mpr fun n => (h n).mpr)⟩

theorem le_multiplicity_map {F : Type*} [FunLike F α β] [MonoidHomClass F α β]
    (f : F) {a b : α} : multiplicity a b ≤ multiplicity (f a) (f b) :=
  multiplicity_le_multiplicity_iff.mpr fun n ↦ by rw [← map_pow]; exact map_dvd f

theorem multiplicity_map_eq {F : Type*} [EquivLike F α β] [MulEquivClass F α β]
    (f : F) {a b : α} : multiplicity (f a) (f b) = multiplicity a b :=
  multiplicity_eq_multiplicity_iff.mpr fun n ↦ by rw [← map_pow]; exact map_dvd_iff f

theorem multiplicity_le_multiplicity_of_dvd_right {a b c : α} (h : b ∣ c) :
    multiplicity a b ≤ multiplicity a c :=
  multiplicity_le_multiplicity_iff.2 fun _ hb => hb.trans h

theorem eq_of_associated_right {a b c : α} (h : Associated b c) :
    multiplicity a b = multiplicity a c :=
  le_antisymm (multiplicity_le_multiplicity_of_dvd_right h.dvd)
    (multiplicity_le_multiplicity_of_dvd_right h.symm.dvd)

theorem dvd_of_multiplicity_pos {a b : α} (h : (0 : PartENat) < multiplicity a b) : a ∣ b := by
  rw [← pow_one a]
  apply pow_dvd_of_le_multiplicity
  simpa only [Nat.cast_one, PartENat.pos_iff_one_le] using h

theorem dvd_iff_multiplicity_pos {a b : α} : (0 : PartENat) < multiplicity a b ↔ a ∣ b :=
  ⟨dvd_of_multiplicity_pos, fun hdvd =>
    lt_of_le_of_ne (zero_le _) fun heq =>
      is_greatest
        (show multiplicity a b < ↑1 by
          simpa only [heq, Nat.cast_zero] using PartENat.coe_lt_coe.mpr zero_lt_one)
        (by rwa [pow_one a])⟩

theorem finite_nat_iff {a b : ℕ} : Finite a b ↔ a ≠ 1 ∧ 0 < b := by
  rw [← not_iff_not, not_finite_iff_forall, not_and_or, Ne, Classical.not_not, not_lt,
    Nat.le_zero]
  exact
    ⟨fun h =>
      or_iff_not_imp_right.2 fun hb =>
        have ha : a ≠ 0 := fun ha => hb <| zero_dvd_iff.mp <| by rw [ha] at h; exact h 1
        Classical.by_contradiction fun ha1 : a ≠ 1 =>
          have ha_gt_one : 1 < a :=
            lt_of_not_ge fun _ =>
              match a with
              | 0 => ha rfl
              | 1 => ha1 rfl
              | b+2 => by omega
          not_lt_of_ge (le_of_dvd (Nat.pos_of_ne_zero hb) (h b)) (lt_pow_self ha_gt_one b),
      fun h => by cases h <;> simp [*]⟩

alias ⟨_, _root_.has_dvd.dvd.multiplicity_pos⟩ := dvd_iff_multiplicity_pos

end Monoid

section CommMonoid

variable [CommMonoid α]

theorem finite_of_finite_mul_left {a b c : α} : Finite a (b * c) → Finite a c := by
  rw [mul_comm]; exact finite_of_finite_mul_right

variable [DecidableRel ((· ∣ ·) : α → α → Prop)]

theorem isUnit_right {a b : α} (ha : ¬IsUnit a) (hb : IsUnit b) : multiplicity a b = 0 :=
  eq_coe_iff.2
    ⟨show a ^ 0 ∣ b by simp only [_root_.pow_zero, one_dvd], by
      rw [pow_one]
      exact fun h => mt (isUnit_of_dvd_unit h) ha hb⟩

theorem one_right {a : α} (ha : ¬IsUnit a) : multiplicity a 1 = 0 :=
  isUnit_right ha isUnit_one

theorem unit_right {a : α} (ha : ¬IsUnit a) (u : αˣ) : multiplicity a u = 0 :=
  isUnit_right ha u.isUnit

open scoped Classical

theorem multiplicity_le_multiplicity_of_dvd_left {a b c : α} (hdvd : a ∣ b) :
    multiplicity b c ≤ multiplicity a c :=
  multiplicity_le_multiplicity_iff.2 fun n h => (pow_dvd_pow_of_dvd hdvd n).trans h

theorem eq_of_associated_left {a b c : α} (h : Associated a b) :
    multiplicity b c = multiplicity a c :=
  le_antisymm (multiplicity_le_multiplicity_of_dvd_left h.dvd)
    (multiplicity_le_multiplicity_of_dvd_left h.symm.dvd)

-- Porting note: this was doing nothing in mathlib3 also
-- alias dvd_iff_multiplicity_pos ↔ _ _root_.has_dvd.dvd.multiplicity_pos

end CommMonoid

section MonoidWithZero

variable [MonoidWithZero α]

theorem ne_zero_of_finite {a b : α} (h : Finite a b) : b ≠ 0 :=
  let ⟨n, hn⟩ := h
  fun hb => by simp [hb] at hn

variable [DecidableRel ((· ∣ ·) : α → α → Prop)]

@[simp]
protected theorem zero (a : α) : multiplicity a 0 = ⊤ :=
  Part.eq_none_iff.2 fun _ ⟨⟨_, hk⟩, _⟩ => hk (dvd_zero _)

@[simp]
theorem multiplicity_zero_eq_zero_of_ne_zero (a : α) (ha : a ≠ 0) : multiplicity 0 a = 0 :=
  multiplicity.multiplicity_eq_zero.2 <| mt zero_dvd_iff.1 ha

end MonoidWithZero

section CommMonoidWithZero

variable [CommMonoidWithZero α]
variable [DecidableRel ((· ∣ ·) : α → α → Prop)]

theorem multiplicity_mk_eq_multiplicity
    [DecidableRel ((· ∣ ·) : Associates α → Associates α → Prop)] {a b : α} :
    multiplicity (Associates.mk a) (Associates.mk b) = multiplicity a b := by
  by_cases h : Finite a b
  · rw [← PartENat.natCast_get (finite_iff_dom.mp h)]
    refine
        (multiplicity.unique
            (show Associates.mk a ^ (multiplicity a b).get h ∣ Associates.mk b from ?_) ?_).symm <;>
      rw [← Associates.mk_pow, Associates.mk_dvd_mk]
    · exact pow_multiplicity_dvd h
    · exact is_greatest
          ((PartENat.lt_coe_iff _ _).mpr (Exists.intro (finite_iff_dom.mp h) (Nat.lt_succ_self _)))
  · suffices ¬Finite (Associates.mk a) (Associates.mk b) by
      rw [finite_iff_dom, PartENat.not_dom_iff_eq_top] at h this
      rw [h, this]
    refine
      not_finite_iff_forall.mpr fun n => by
        rw [← Associates.mk_pow, Associates.mk_dvd_mk]
        exact not_finite_iff_forall.mp h n

end CommMonoidWithZero

section Semiring

variable [Semiring α] [DecidableRel ((· ∣ ·) : α → α → Prop)]

theorem min_le_multiplicity_add {p a b : α} :
    min (multiplicity p a) (multiplicity p b) ≤ multiplicity p (a + b) :=
  (le_total (multiplicity p a) (multiplicity p b)).elim
    (fun h ↦ by
      rw [min_eq_left h, multiplicity_le_multiplicity_iff]
      exact fun n hn => dvd_add hn (multiplicity_le_multiplicity_iff.1 h n hn))
    fun h ↦ by
      rw [min_eq_right h, multiplicity_le_multiplicity_iff]
      exact fun n hn => dvd_add (multiplicity_le_multiplicity_iff.1 h n hn) hn

end Semiring

section Ring

variable [Ring α] [DecidableRel ((· ∣ ·) : α → α → Prop)]

@[simp]
protected theorem neg (a b : α) : multiplicity a (-b) = multiplicity a b :=
  Part.ext' (by simp only [multiplicity, PartENat.find, dvd_neg]) fun h₁ h₂ =>
    PartENat.natCast_inj.1 (by
      rw [PartENat.natCast_get]
      exact Eq.symm
              (unique (pow_multiplicity_dvd _).neg_right
                (mt dvd_neg.1 (is_greatest' _ (lt_succ_self _)))))

theorem Int.natAbs (a : ℕ) (b : ℤ) : multiplicity a b.natAbs = multiplicity (a : ℤ) b := by
  cases' Int.natAbs_eq b with h h <;> conv_rhs => rw [h]
  · rw [Int.natCast_multiplicity]
  · rw [multiplicity.neg, Int.natCast_multiplicity]

theorem multiplicity_add_of_gt {p a b : α} (h : multiplicity p b < multiplicity p a) :
    multiplicity p (a + b) = multiplicity p b := by
  apply le_antisymm
  · apply PartENat.le_of_lt_add_one
    cases' PartENat.ne_top_iff.mp (PartENat.ne_top_of_lt h) with k hk
    rw [hk]
    rw_mod_cast [multiplicity_lt_iff_not_dvd, dvd_add_right]
    · intro h_dvd
      apply multiplicity.is_greatest _ h_dvd
      rw [hk, ← Nat.succ_eq_add_one]
      norm_cast
      apply Nat.lt_succ_self k
    · rw [pow_dvd_iff_le_multiplicity, Nat.cast_add, ← hk, Nat.cast_one]
      exact PartENat.add_one_le_of_lt h
  · have := @min_le_multiplicity_add α _ _ p a b
    rwa [← min_eq_right (le_of_lt h)]

theorem multiplicity_sub_of_gt {p a b : α} (h : multiplicity p b < multiplicity p a) :
    multiplicity p (a - b) = multiplicity p b := by
  rw [sub_eq_add_neg, multiplicity_add_of_gt] <;> rw [multiplicity.neg]; assumption

theorem multiplicity_add_eq_min {p a b : α} (h : multiplicity p a ≠ multiplicity p b) :
    multiplicity p (a + b) = min (multiplicity p a) (multiplicity p b) := by
  rcases lt_trichotomy (multiplicity p a) (multiplicity p b) with (hab | hab | hab)
  · rw [add_comm, multiplicity_add_of_gt hab, min_eq_left]
    exact le_of_lt hab
  · contradiction
  · rw [multiplicity_add_of_gt hab, min_eq_right]
    exact le_of_lt hab

end Ring

section CancelCommMonoidWithZero

variable [CancelCommMonoidWithZero α]

/- Porting note:
Pulled a b intro parameters since Lean parses that more easily -/
theorem finite_mul_aux {p : α} (hp : Prime p) {a b : α} :
    ∀ {n m : ℕ}, ¬p ^ (n + 1) ∣ a → ¬p ^ (m + 1) ∣ b → ¬p ^ (n + m + 1) ∣ a * b
  | n, m => fun ha hb ⟨s, hs⟩ =>
    have : p ∣ a * b := ⟨p ^ (n + m) * s, by simp [hs, pow_add, mul_comm, mul_assoc, mul_left_comm]⟩
    (hp.2.2 a b this).elim
      (fun ⟨x, hx⟩ =>
        have hn0 : 0 < n :=
          Nat.pos_of_ne_zero fun hn0 => by simp [hx, hn0] at ha
        have hpx : ¬p ^ (n - 1 + 1) ∣ x := fun ⟨y, hy⟩ =>
          ha (hx.symm ▸ ⟨y, mul_right_cancel₀ hp.1 <| by
            rw [tsub_add_cancel_of_le (succ_le_of_lt hn0)] at hy
            simp [hy, pow_add, mul_comm, mul_assoc, mul_left_comm]⟩)
        have : 1 ≤ n + m := le_trans hn0 (Nat.le_add_right n m)
        finite_mul_aux hp hpx hb
          ⟨s, mul_right_cancel₀ hp.1 (by
                rw [tsub_add_eq_add_tsub (succ_le_of_lt hn0), tsub_add_cancel_of_le this]
                simp_all [mul_comm, mul_assoc, mul_left_comm, pow_add])⟩)
      fun ⟨x, hx⟩ =>
        have hm0 : 0 < m :=
          Nat.pos_of_ne_zero fun hm0 => by simp [hx, hm0] at hb
        have hpx : ¬p ^ (m - 1 + 1) ∣ x := fun ⟨y, hy⟩ =>
          hb
            (hx.symm ▸
              ⟨y,
                mul_right_cancel₀ hp.1 <| by
                  rw [tsub_add_cancel_of_le (succ_le_of_lt hm0)] at hy
                  simp [hy, pow_add, mul_comm, mul_assoc, mul_left_comm]⟩)
        finite_mul_aux hp ha hpx
        ⟨s, mul_right_cancel₀ hp.1 (by
              rw [add_assoc, tsub_add_cancel_of_le (succ_le_of_lt hm0)]
              simp_all [mul_comm, mul_assoc, mul_left_comm, pow_add])⟩

theorem finite_mul {p a b : α} (hp : Prime p) : Finite p a → Finite p b → Finite p (a * b) :=
  fun ⟨n, hn⟩ ⟨m, hm⟩ => ⟨n + m, finite_mul_aux hp hn hm⟩

theorem finite_mul_iff {p a b : α} (hp : Prime p) : Finite p (a * b) ↔ Finite p a ∧ Finite p b :=
  ⟨fun h => ⟨finite_of_finite_mul_right h, finite_of_finite_mul_left h⟩, fun h =>
    finite_mul hp h.1 h.2⟩

theorem finite_pow {p a : α} (hp : Prime p) : ∀ {k : ℕ} (_ : Finite p a), Finite p (a ^ k)
  | 0, _ => ⟨0, by simp [mt isUnit_iff_dvd_one.2 hp.2.1]⟩
  | k + 1, ha => by rw [_root_.pow_succ']; exact finite_mul hp ha (finite_pow hp ha)

variable [DecidableRel ((· ∣ ·) : α → α → Prop)]

@[simp]
theorem multiplicity_self {a : α} (ha : ¬IsUnit a) (ha0 : a ≠ 0) : multiplicity a a = 1 := by
  rw [← Nat.cast_one]
  exact eq_coe_iff.2 ⟨by simp, fun ⟨b, hb⟩ => ha (isUnit_iff_dvd_one.2
            ⟨b, mul_left_cancel₀ ha0 <| by simpa [_root_.pow_succ, mul_assoc] using hb⟩)⟩

@[simp]
theorem get_multiplicity_self {a : α} (ha : Finite a a) : get (multiplicity a a) ha = 1 :=
  PartENat.get_eq_iff_eq_coe.2
    (eq_coe_iff.2
      ⟨by simp, fun ⟨b, hb⟩ => by
        rw [← mul_one a, pow_add, pow_one, mul_assoc, mul_assoc,
            mul_right_inj' (ne_zero_of_finite ha)] at hb
        exact mt isUnit_iff_dvd_one.2 (not_unit_of_finite ha) ⟨b, by simp_all⟩⟩)

protected theorem mul' {p a b : α} (hp : Prime p) (h : (multiplicity p (a * b)).Dom) :
    get (multiplicity p (a * b)) h =
      get (multiplicity p a) ((finite_mul_iff hp).1 h).1 +
        get (multiplicity p b) ((finite_mul_iff hp).1 h).2 := by
  have hdiva : p ^ get (multiplicity p a) ((finite_mul_iff hp).1 h).1 ∣ a := pow_multiplicity_dvd _
  have hdivb : p ^ get (multiplicity p b) ((finite_mul_iff hp).1 h).2 ∣ b := pow_multiplicity_dvd _
  have hpoweq :
    p ^ (get (multiplicity p a) ((finite_mul_iff hp).1 h).1 +
          get (multiplicity p b) ((finite_mul_iff hp).1 h).2) =
      p ^ get (multiplicity p a) ((finite_mul_iff hp).1 h).1 *
        p ^ get (multiplicity p b) ((finite_mul_iff hp).1 h).2 := by
    simp [pow_add]
  have hdiv :
    p ^ (get (multiplicity p a) ((finite_mul_iff hp).1 h).1 +
          get (multiplicity p b) ((finite_mul_iff hp).1 h).2) ∣
      a * b := by
    rw [hpoweq]; apply mul_dvd_mul <;> assumption
  have hsucc :
    ¬p ^ (get (multiplicity p a) ((finite_mul_iff hp).1 h).1 +
              get (multiplicity p b) ((finite_mul_iff hp).1 h).2 +
            1) ∣
        a * b :=
    fun h =>
    not_or_intro (is_greatest' _ (lt_succ_self _)) (is_greatest' _ (lt_succ_self _))
      (_root_.succ_dvd_or_succ_dvd_of_succ_sum_dvd_mul hp hdiva hdivb h)
  rw [← PartENat.natCast_inj, PartENat.natCast_get, eq_coe_iff]; exact ⟨hdiv, hsucc⟩

open scoped Classical

protected theorem mul {p a b : α} (hp : Prime p) :
    multiplicity p (a * b) = multiplicity p a + multiplicity p b :=
  if h : Finite p a ∧ Finite p b then by
    rw [← PartENat.natCast_get (finite_iff_dom.1 h.1), ←
        PartENat.natCast_get (finite_iff_dom.1 h.2), ←
        PartENat.natCast_get (finite_iff_dom.1 (finite_mul hp h.1 h.2)), ← Nat.cast_add,
        PartENat.natCast_inj, multiplicity.mul' hp]
  else by
    rw [eq_top_iff_not_finite.2 (mt (finite_mul_iff hp).1 h)]
    cases' not_and_or.1 h with h h <;> simp [eq_top_iff_not_finite.2 h]

theorem Finset.prod {β : Type*} {p : α} (hp : Prime p) (s : Finset β) (f : β → α) :
    multiplicity p (∏ x ∈ s, f x) = ∑ x ∈ s, multiplicity p (f x) := by
  classical
    induction' s using Finset.induction with a s has ih h
    · simp only [Finset.sum_empty, Finset.prod_empty]
      convert one_right hp.not_unit
    · simpa [has, ← ih] using multiplicity.mul hp

-- Porting note: with protected could not use pow' k in the succ branch
protected theorem pow' {p a : α} (hp : Prime p) (ha : Finite p a) :
    ∀ {k : ℕ}, get (multiplicity p (a ^ k)) (finite_pow hp ha) = k * get (multiplicity p a) ha := by
  intro k
  induction' k with k hk
  · simp [one_right hp.not_unit]
  · have : multiplicity p (a ^ (k + 1)) = multiplicity p (a * a ^ k) := by rw [_root_.pow_succ']
    rw [get_eq_get_of_eq _ _ this,
      multiplicity.mul' hp, hk, add_mul, one_mul, add_comm]

theorem pow {p a : α} (hp : Prime p) : ∀ {k : ℕ}, multiplicity p (a ^ k) = k • multiplicity p a
  | 0 => by simp [one_right hp.not_unit]
  | succ k => by simp [_root_.pow_succ, succ_nsmul, pow hp, multiplicity.mul hp]

theorem multiplicity_pow_self {p : α} (h0 : p ≠ 0) (hu : ¬IsUnit p) (n : ℕ) :
    multiplicity p (p ^ n) = n := by
  rw [eq_coe_iff]
  use dvd_rfl
  rw [pow_dvd_pow_iff h0 hu]
  apply Nat.not_succ_le_self

theorem multiplicity_pow_self_of_prime {p : α} (hp : Prime p) (n : ℕ) :
    multiplicity p (p ^ n) = n :=
  multiplicity_pow_self hp.ne_zero hp.not_unit n

end CancelCommMonoidWithZero

end multiplicity

section Nat

open multiplicity

theorem multiplicity_eq_zero_of_coprime {p a b : ℕ} (hp : p ≠ 1)
    (hle : multiplicity p a ≤ multiplicity p b) (hab : Nat.Coprime a b) : multiplicity p a = 0 := by
  rw [multiplicity_le_multiplicity_iff] at hle
  rw [← nonpos_iff_eq_zero, ← not_lt, PartENat.pos_iff_one_le, ← Nat.cast_one, ←
    pow_dvd_iff_le_multiplicity]
  intro h
  have := Nat.dvd_gcd h (hle _ h)
  rw [Coprime.gcd_eq_one hab, Nat.dvd_one, pow_one] at this
  exact hp this

end Nat

namespace multiplicity

theorem finite_int_iff_natAbs_finite {a b : ℤ} : Finite a b ↔ Finite a.natAbs b.natAbs := by
  simp only [finite_def, ← Int.natAbs_dvd_natAbs, Int.natAbs_pow]

theorem finite_int_iff {a b : ℤ} : Finite a b ↔ a.natAbs ≠ 1 ∧ b ≠ 0 := by
  rw [finite_int_iff_natAbs_finite, finite_nat_iff, pos_iff_ne_zero, Int.natAbs_ne_zero]

instance decidableNat : DecidableRel fun a b : ℕ => (multiplicity a b).Dom := fun _ _ =>
  decidable_of_iff _ finite_nat_iff.symm

instance decidableInt : DecidableRel fun a b : ℤ => (multiplicity a b).Dom := fun _ _ =>
  decidable_of_iff _ finite_int_iff.symm

end multiplicity
