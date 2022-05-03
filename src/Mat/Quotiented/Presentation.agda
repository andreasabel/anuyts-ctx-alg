{-# OPTIONS --cubical --type-in-type #-}

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Function
open import Cubical.Data.List.FinData renaming (lookup to _!_)
open import Cubical.Data.Sigma
open import Cubical.Categories.Category

open import Mat.Signature
open import Mat.Free.Presentation
import Mat.Free.Term

module Mat.Quotiented.Presentation where

module EqTheory {sign : Signature} (presF : PresentationF sign) where
  open Signature sign
  open PresentationF presF
  open Mat.Free.Term presF
  record EqTheory : Type where

    field
      Axiom : Sort → Type
      isSetAxiom : {sortOut : Sort} → isSet (Axiom sortOut)
      msetArity : ∀ {sortOut} → Axiom sortOut → MSet
      lhs rhs : ∀ {sortOut : Sort} → (axiom : Axiom sortOut) → TermF (mtyp (msetArity axiom)) sortOut

  module _ (eqTheory : EqTheory) where
    open EqTheory eqTheory public

    -- Congruence equivalence relation generated by the axioms
    data Eq {X} : ∀ {sort} (t1 t2 : TermF X sort) → Type where
      reflEq : ∀ {sort} {t : TermF X sort} → Eq t t
      symEq : ∀ {sort} {t1 t2 : TermF X sort} → Eq t1 t2 → Eq t2 t1
      transEq : ∀ {sort} {t1 t2 t3 : TermF X sort} → Eq t1 t2 → Eq t2 t3 → Eq t1 t3
      axiomEq : ∀ {sort} (axiom : Axiom sort) (f : ∀ sort → mtyp (msetArity axiom) sort → TermF X sort)
        → Eq (joinTermF sort (mapTermF f sort (lhs axiom)))
              (joinTermF sort (mapTermF f sort (rhs axiom)))
      astEq : ∀ {sort} (o : Operation sort)
        (args : Arguments (λ sort' → Σ[ (t1 , t2) ∈ TermF X sort' × TermF X sort' ] Eq t1 t2) (arity o))
        → Eq (astF (term1 o λ p → fst (fst (args p))))
              (astF (term1 o λ p → snd (fst (args p))))

    data Term (X : MType) : (sort : Sort) → Type where
      term : ∀ {sort} → TermF X sort → Term X sort
      eqTerm : ∀ {sort} {t1 t2 : TermF X sort} → Eq t1 t2 → term t1 ≡ term t2
      isSetTerm : ∀ {sort} → isSet (Term X sort)

    pattern var x = term (varF x)

    ast : ∀ {X sort} → Term1 (Term X) sort → Term X sort
    ast t = {!!} -- this is not even possible!

    {-
    -- Syntax monad
    data Term (X : MType) : (sortOut : Sort) → Type
    --joinTermFTerm : {X : MType} → (sort : Sort) → TermF (Term X) sort → Term X sort
    bindTermFTerm : {X Y : MType} → (f : ∀ sort → Y sort → Term X sort) → (sort : Sort) → TermF Y sort → Term X sort
    --termFtoQ : {X : MType} → (sort : Sort) → TermF X sort → Term X sort
    --joinTerm : {X : MType} → (sort : Sort) → Term (Term X) sort → Term X sort

    data Term X where
      var : ∀ {sortOut} → X sortOut → Term X sortOut
      ast : ∀ {sortOut} → Term1 (Term X) sortOut → Term X sortOut
      byAxiom : ∀ {sortOut} → (axiom : Axiom sortOut) → (f : ∀ sort → mtyp (msetArity axiom) sort → Term X sort)
        → bindTermFTerm f sortOut (lhs axiom)
        ≡ bindTermFTerm f sortOut (rhs axiom)
      isSetTerm : ∀ {sortOut} → isSet (Term X sortOut)

    --joinTermFTerm sort (varF t) = t
    --joinTermFTerm sort (astF (term1 o args)) = ast (term1 o λ p → joinTermFTerm (arity o ! p) (args p))
    bindTermFTerm f sort (varF y) = f sort y
    bindTermFTerm f sort (astF (term1 o args)) = ast (term1 o λ p → bindTermFTerm f (arity o ! p) (args p))

    {-# TERMINATING #-}
    joinTerm : {X : MType} → (sort : Sort) → Term (Term X) sort → Term X sort
    joinTermByAxiom : ∀ {X : MType} (sort : Sort) (axiom : Axiom sort)
      (f : ∀ sort' → mtyp (msetArity axiom) sort' → Term (Term X) sort')
      → joinTerm sort (bindTermFTerm f sort (lhs axiom))
      ≡ joinTerm sort (bindTermFTerm f sort (rhs axiom))
    joinTerm-bindTermFTerm : {X Y : MType} → (f : ∀ sort → Y sort → Term (Term X) sort)
      → (sort : Sort) → (t : TermF Y sort)
      → joinTerm sort (bindTermFTerm f sort t)
      ≡ bindTermFTerm (λ sort' y → joinTerm sort' (f sort' y)) sort t

    joinTerm sort (var t) = t
    joinTerm sort (ast (term1 o args)) = ast (term1 o λ p → joinTerm (arity o ! p) (args p))
    joinTerm sort (byAxiom axiom f i) = hcomp
      (λ where
        j (i = i0) → joinTerm-bindTermFTerm f sort (lhs axiom) (~ j)
        j (i = i1) → joinTerm-bindTermFTerm f sort (rhs axiom) (~ j)
      )
      (byAxiom axiom (λ sort' y → joinTerm sort' (f sort' y)) i)
      --joinTermByAxiom sort axiom f i
      {-(joinTerm-bindTermFTerm f sort (lhs axiom)
      ∙∙
      byAxiom axiom (λ sort' y → joinTerm sort' (f sort' y))
      ∙∙
      sym (joinTerm-bindTermFTerm f sort (rhs axiom))) i-}
    joinTerm sort (isSetTerm t1 t2 et et' i j) =
      isSetTerm (joinTerm sort t1) (joinTerm sort t2) (cong (joinTerm sort) et) (cong (joinTerm sort) et') i j
    joinTermByAxiom sort axiom f =
      joinTerm-bindTermFTerm f sort (lhs axiom)
      ∙∙
      byAxiom axiom (λ sort' y → joinTerm sort' (f sort' y))
      ∙∙
      sym (joinTerm-bindTermFTerm f sort (rhs axiom))
    joinTerm-bindTermFTerm f sort (varF x) = refl
    joinTerm-bindTermFTerm f sort (astF (term1 o args)) =
      cong ast (cong (term1 o) (funExt λ p i → joinTerm-bindTermFTerm f (arity o ! p) (args p) i))

    -- Term acting on MSets
    msetTerm : MSet → MSet
    fst (msetTerm msetX sortOut) = Term (mtyp msetX) sortOut
    snd (msetTerm msetX sortOut) = isSetTerm
  -}

  {-
  data Term X where
    var : ∀ {sortOut} → X sortOut → Term X sortOut
    ast : ∀ {sortOut} → Term1 (Term X) sortOut → Term X sortOut
    astQ : ∀ {sortOut} → TermF (Term X) sortOut → Term X sortOut
    astQ-varF : ∀ {sortOut} → (t : Term X sortOut) → astQ (varF t) ≡ t
    astQ-astF : ∀ {sortOut} → (t : Term1 (TermF (Term X)) sortOut)
      → astQ (astF t) ≡ ast (mapTerm1 (λ sort → astQ) sortOut t)
    byAxiom : ∀ {sortOut} → (axiom : Axiom sortOut) → (f : ∀ sort → mtyp (msetArity axiom) sort → Term X sort)
      → astQ (mapTermF f sortOut (lhs axiom))
       ≡ astQ (mapTermF f sortOut (rhs axiom))
    --byAxiom : ∀ {sortOut} → (axiom : Axiom sortOut) → (f : ∀ sort → mtyp (msetArity axiom) sort → Term X sort)
    --  → joinTerm sortOut (termFtoQ sortOut (mapTermF f sortOut (lhs axiom)))
    --   ≡ joinTerm sortOut (termFtoQ sortOut (mapTermF f sortOut (rhs axiom)))
    isSetTerm : ∀ {sortOut} → isSet (Term X sortOut)

  isSetTerm' msetX sortOut = isSetTerm

  --termFtoQ sort (varF x) = var x
  --termFtoQ sort (astF (term1 o args)) = ast (term1 o λ p → termFtoQ (arity o ! p) (args p))

  --joinTerm sort (var t) = t
  --joinTerm sort (ast (term1 o args)) = ast (term1 o λ p → joinTerm (arity o ! p) (args p))
  --joinTerm sort (byAxiom axiom f i) = {!!}
  --joinTerm sort (isSetTerm t t₁ x y i i₁) = {!!}
  
  joinTerm : {X : MType} → (sort : Sort) → Term (Term X) sort → Term X sort
  mapTermF-joinTerm : {X : MType} → (sort : Sort) → TermF (Term (Term X)) sort → TermF (Term X) sort
  mapTerm1-mapTermF-joinTerm : {X : MType} → (sort : Sort) → Term1 (TermF (Term (Term X))) sort → Term1 (TermF (Term X)) sort
  mapTermF-joinTerm-f : {X Y : MType}
    → (f : ∀ sort → Y sort → Term (Term X) sort)
    → (sort : Sort) → (t : TermF Y sort)
    → mapTermF (λ sort' → joinTerm sort' ∘ f sort') sort t ≡ mapTermF-joinTerm sort (mapTermF f sort t)

  joinTerm sort (var t) = t
  joinTerm sort (ast (term1 o args)) = ast (term1 o λ p → joinTerm (arity o ! p) (args p))
  joinTerm sort (astQ t) = astQ (mapTermF-joinTerm sort t)
  joinTerm sort (astQ-varF t i) = astQ-varF (joinTerm sort t) i
  joinTerm sort (astQ-astF t i) = astQ-astF (mapTerm1-mapTermF-joinTerm sort t) i
  joinTerm sort (byAxiom axiom f i) = hcomp
    (λ where
        j (i = i0) → astQ (mapTermF-joinTerm-f f sort (lhs axiom) j)
        j (i = i1) → astQ (mapTermF-joinTerm-f f sort (rhs axiom) j)
    )
    (byAxiom axiom (λ sort' y → joinTerm sort' (f sort' y)) i)
  joinTerm sort (isSetTerm t t₁ x y i i₁) = {!!}
  mapTermF-joinTerm sort (varF t) = varF (joinTerm sort t)
  mapTermF-joinTerm sort (astF t) = astF (mapTerm1-mapTermF-joinTerm sort t)
  mapTerm1-mapTermF-joinTerm sort (term1 o args) = term1 o λ p → mapTermF-joinTerm (arity o ! p) (args p)
  mapTermF-joinTerm-f f sort t = {!!}
  -}

EqTheory = EqTheory.EqTheory

record Presentation (sign : Signature) : Type where
  constructor presentationQ
  field
    getPresentationF : PresentationF sign
    getEqTheory : EqTheory getPresentationF
