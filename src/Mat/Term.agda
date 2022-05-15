{-# OPTIONS --cubical --type-in-type #-}

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Function
open import Cubical.Foundations.Isomorphism renaming (Iso to _≅_)
open import Cubical.Data.List.FinData renaming (lookup to _!_)
open import Cubical.Data.Sigma
open import Cubical.Foundations.Structure hiding (str)
open import Cubical.Categories.Category
import Cubical.Categories.Category.Precategory as P
open import Cubical.Categories.Functor
open import Cubical.Categories.NaturalTransformation
open import Cubical.Categories.Monad.Base
open import Cubical.Categories.Instances.FunctorAlgebras
open import Cubical.Categories.Instances.EilenbergMoore
open import Cubical.Categories.Instances.Categories
open import Cubical.Categories.Adjoint
open import Cubical.Categories.Constructions.FullSubcategory

open import Mat.Signature
open import Mat.Free.Presentation
import Mat.Free.Term
open import Mat.Presentation

-- Terms of the MAT generated by a MAT presentation
module Mat.Term {sign : Signature} (mat : Presentation sign) where

open Signature sign
open Presentation
open PresentationF (getPresentationF mat)
open Mat.Free.Term (getPresentationF mat)
open EqTheory (getEqTheory mat)

open Category hiding (_∘_)
open Functor
open Algebra
open IsMonad
open NatTrans
open IsEMAlgebra
open NaturalBijection
open _⊣_
open AlgebraHom
open _≅_
module P≅ = P.PrecatIso

-- Syntax monad
data Term (X : MType) : (sort : Sort) → Type where
  var : ∀ {sortOut} → X sortOut → Term X sortOut
  ast : ∀ {sortOut} → Term1 (Term X) sortOut → Term X sortOut
  joinFQ : ∀ {sortOut} → TermF (Term X) sortOut → Term X sortOut
  joinFQ-varF : ∀ {sortOut} → (t : Term X sortOut) → joinFQ (varF t) ≡ t
  joinFQ-astF : ∀ {sortOut} → (t : Term1 (TermF (Term X)) sortOut)
    → joinFQ (astF t) ≡ ast (mapTerm1 (λ sort → joinFQ) sortOut t)
  byAxiom : ∀ {sortOut : Sort} → (axiom : Axiom sortOut) → (f : ∀ sort → mtyp (msetArity axiom) sort → Term X sort)
    → joinFQ (mapTermF f sortOut (lhs axiom))
    ≡ joinFQ (mapTermF f sortOut (rhs axiom))
  isSetTerm : ∀ {sortOut} → isSet (Term X sortOut)

-- Term acting on MSets
msetTerm : MSet → MSet
fst (msetTerm msetX sortOut) = Term (mtyp msetX) sortOut
snd (msetTerm msetX sortOut) = isSetTerm

-- Components of Term as a functor
{-# TERMINATING #-}
mapTerm : ∀ {X Y} → (∀ sort → X sort → Y sort) → ∀ sort → Term X sort → Term Y sort
mapTerm f sort (var x) = var (f sort x)
mapTerm f sort (ast t) = ast (mapTerm1 (mapTerm f) sort t)
mapTerm f sort (joinFQ t) = joinFQ (mapTermF (mapTerm f) sort t)
mapTerm f sort (joinFQ-varF t i) = joinFQ-varF (mapTerm f sort t) i
mapTerm f sort (joinFQ-astF t i) = joinFQ-astF (mapTerm1 (mapTermF (mapTerm f)) sort t) i
mapTerm f sort (byAxiom axiom g i) = hcomp
  (λ where
    j (i = i0) → joinFQ (mapTermF-∘ (mapTerm f) g j sort (lhs axiom))
    j (i = i1) → joinFQ (mapTermF-∘ (mapTerm f) g j sort (rhs axiom))
  )
  (byAxiom axiom (λ sort' y → mapTerm f sort' (g sort' y)) i)
mapTerm f sort (isSetTerm t1 t2 et et' i j) = isSetTerm
  (mapTerm f sort t1)
  (mapTerm f sort t2)
  (λ k → mapTerm f sort (et k))
  (λ k → mapTerm f sort (et' k)) i j

{-# TERMINATING #-}
mapTerm-id : ∀ {X} → mapTerm (λ sort → idfun (X sort)) ≡ (λ sort → idfun (Term X sort))
mapTermF-mapTerm-id : ∀ {X} → mapTermF (mapTerm (λ sort → idfun (X sort))) ≡ (λ sort → idfun (TermF (Term X) sort))
mapTerm-id i sort (var x) = var x
mapTerm-id i sort (ast t) = ast (mapTerm1 (mapTerm-id i) sort t)
mapTerm-id i sort (joinFQ t) = joinFQ (mapTermF-mapTerm-id i sort t)
mapTerm-id {X = X} i sort (joinFQ-varF t j) = --{!joinFQ-varF (mapTerm-id i sort t) j!}
  idfun
    (Square
      (λ j → joinFQ-varF (mapTerm (λ sort₁ → idfun (X sort₁)) sort t) j)
      (λ j → idfun (Term X sort) (joinFQ-varF t j))
      (λ i → joinFQ (mapTermF-mapTerm-id i sort (varF t)))
      (λ i → mapTerm-id i sort t)
    ) (toPathP (isSetTerm _ _ _ _)) i j
mapTerm-id i sort (joinFQ-astF (term1 o args) j) =
  idfun
    (Square
      (λ j → joinFQ-astF (term1 o (λ p → mapTermF (mapTerm (λ sort₁ x → x)) (arity o ! p) (args p))) j)
      (λ j → joinFQ-astF (term1 o args) j)
      (λ i →  joinFQ (mapTermF-mapTerm-id i sort (astF (term1 o args)))
      )
      (λ i →  ast (term1 o λ p → joinFQ (mapTermF-mapTerm-id i (arity o ! p) (args p)))
      )
    ) (toPathP (isSetTerm _ _ _ _)) i j
mapTerm-id {X = X} k sort (byAxiom axiom f i) =
  idfun
    (Square
      (λ i → mapTerm (λ _ x → x) sort (byAxiom axiom f i))
      (λ i → byAxiom axiom f i)
      (λ k → joinFQ (mapTermF-mapTerm-id k sort (mapTermF f sort (lhs axiom))))
      λ k → joinFQ (mapTermF-mapTerm-id k sort (mapTermF f sort (rhs axiom)))
    ) (toPathP (isSetTerm _ _ _ _)) k i
mapTerm-id i sort (isSetTerm t1 t2 et et' j k) = isSetTerm
  (mapTerm-id i sort t1)
  (mapTerm-id i sort t2)
  (λ k → mapTerm-id i sort (et k))
  (λ k → mapTerm-id i sort (et' k)) j k
mapTermF-mapTerm-id i = idfun (mapTermF (mapTerm (λ sort₁ x₁ → x₁)) ≡ (λ _ t → t))
  (cong mapTermF mapTerm-id ∙ mapTermF-id)
  i

{-# TERMINATING #-}
mapTerm-∘ : ∀ {X Y Z : MType}
  → (g : ∀ sort → Y sort → Z sort)
  → (f : ∀ sort → X sort → Y sort)
  → mapTerm (λ sort → g sort ∘ f sort) ≡ (λ sort → mapTerm g sort ∘ mapTerm f sort)
mapTermF-mapTerm-∘ : ∀ {X Y Z : MType}
  → (g : ∀ sort → Y sort → Z sort)
  → (f : ∀ sort → X sort → Y sort)
  → mapTermF (mapTerm (λ sort → g sort ∘ f sort)) ≡ (λ sort → mapTermF (mapTerm g) sort ∘ mapTermF (mapTerm f) sort)
mapTerm-∘ g f i sort (var x) = var (g sort (f sort x))
mapTerm-∘ g f i sort (ast t) = ast (mapTerm1 (mapTerm-∘ g f i) sort t)
mapTerm-∘ g f i sort (joinFQ t) = joinFQ (mapTermF-mapTerm-∘ g f i sort t)
mapTerm-∘ g f i sort (joinFQ-varF t j) =
  idfun
    (Square
      (λ j → joinFQ-varF (mapTerm (λ sort₁ → g sort₁ ∘ f sort₁) sort t) j)
      (λ j → (mapTerm g sort ∘ mapTerm f sort) (joinFQ-varF t j))
      (λ i → joinFQ (mapTermF-mapTerm-∘ g f i sort (varF t)))
      λ i → mapTerm-∘ g f i sort t
    )
    (toPathP (isSetTerm _ _ _ _)) i j
mapTerm-∘ g f i sort (joinFQ-astF (term1 o args) j) =
  idfun
    (Square
      (λ j → joinFQ-astF (term1 o (λ p →
        mapTermF (mapTerm (λ sort₁ x → g sort₁ (f sort₁ x))) (arity o ! p) (args p))) j)
      (λ j → joinFQ-astF (term1 o (λ p →
        mapTermF (mapTerm g) (arity o ! p) (mapTermF (mapTerm f) (arity o ! p) (args p)))) j)
      (λ i → joinFQ (mapTermF-mapTerm-∘ g f i sort (astF (term1 o args))))
      (λ i → ast (term1 o λ p → joinFQ (mapTermF-mapTerm-∘ g f i (arity o ! p) (args p))))
    )
    (toPathP (isSetTerm _ _ _ _)) i j
mapTerm-∘ g f k sort (byAxiom axiom h i) =
  idfun
    (Square
      (λ i → mapTerm (λ sort₁ → g sort₁ ∘ f sort₁) sort (byAxiom axiom h i))
      (λ i → (mapTerm g sort ∘ mapTerm f sort) (byAxiom axiom h i))
      (λ k → joinFQ (mapTermF-mapTerm-∘ g f k sort (mapTermF h sort (lhs axiom))))
      (λ k → joinFQ (mapTermF-mapTerm-∘ g f k sort (mapTermF h sort (rhs axiom))))
    ) (toPathP (isSetTerm _ _ _ _)) k i
mapTerm-∘ g f i sort (isSetTerm t1 t2 et et' j k) = isSetTerm
  (mapTerm-∘ g f i sort t1)
  (mapTerm-∘ g f i sort t2)
  (λ k → mapTerm-∘ g f i sort (et k))
  (λ k → mapTerm-∘ g f i sort (et' k)) j k
mapTermF-mapTerm-∘ g f = cong mapTermF (mapTerm-∘ g f) ∙ mapTermF-∘ (mapTerm g) (mapTerm f)

-- Term as a functor on catMSet
ftrTerm : Functor catMSet catMSet
F-ob ftrTerm = msetTerm
F-hom ftrTerm = mapTerm
F-id ftrTerm = mapTerm-id
F-seq ftrTerm f g = mapTerm-∘ g f

-- Components of Term as a monad
pureTerm : {X : MType} → (sort : Sort) → X sort → Term X sort
pureTerm sort x = var x

{-# TERMINATING #-}
joinTerm : {X : MType} → (sort : Sort) → Term (Term X) sort → Term X sort
joinTerm sort (var t) = t
joinTerm sort (ast t) = ast (mapTerm1 joinTerm sort t)
joinTerm sort (joinFQ t) = joinFQ (mapTermF joinTerm sort t)
joinTerm sort (joinFQ-varF t i) = joinFQ-varF (joinTerm sort t) i
joinTerm sort (joinFQ-astF t i) = joinFQ-astF (mapTerm1 (mapTermF joinTerm) sort t) i
joinTerm sort (byAxiom axiom f i) = hcomp
  (λ where
     j (i = i0) → joinFQ (mapTermF-∘ joinTerm f j sort (lhs axiom))
     j (i = i1) → joinFQ (mapTermF-∘ joinTerm f j sort (rhs axiom))
  )
  (byAxiom axiom (λ sort' y → joinTerm sort' (f sort' y)) i)
joinTerm sort (isSetTerm t1 t2 et et' i j) = isSetTerm
  (joinTerm sort t1)
  (joinTerm sort t2)
  (λ k → joinTerm sort (et k))
  (λ k → joinTerm sort (et' k)) i j

{-# TERMINATING #-}
joinTerm-nat : ∀ {X Y : MType} → (f : ∀ sort → X sort → Y sort) →
  (λ sort → joinTerm sort ∘ mapTerm (mapTerm f) sort)
  ≡ (λ sort → mapTerm f sort ∘ joinTerm sort)
mapTermF-joinTerm-nat : ∀ {X Y : MType} → (f : ∀ sort → X sort → Y sort) →
  (λ sort → mapTermF joinTerm sort ∘ mapTermF (mapTerm (mapTerm f)) sort)
  ≡ (λ sort → mapTermF (mapTerm f) sort ∘ mapTermF joinTerm sort)
joinTerm-nat f i sort (var t) = mapTerm f sort t
joinTerm-nat f i sort (ast t) = ast (mapTerm1 (joinTerm-nat f i) sort t)
joinTerm-nat f i sort (joinFQ t) = joinFQ (mapTermF-joinTerm-nat f i sort t)
joinTerm-nat f i sort (joinFQ-varF t j) =
  idfun
    (Square
      (λ j → (joinTerm sort ∘ mapTerm (mapTerm f) sort) (joinFQ-varF t j))
      (λ j → (mapTerm f sort ∘ joinTerm sort) (joinFQ-varF t j))
      (λ i → joinFQ (mapTermF-joinTerm-nat f i sort (varF t)))
      (λ i → joinTerm-nat f i sort t)
    )
    (toPathP (isSetTerm _ _ _ _)) i j
joinTerm-nat f i sort (joinFQ-astF t@(term1 o args) j) =
  idfun
    (Square
      (λ j → joinFQ-astF (mapTerm1 (mapTermF joinTerm) sort
        (mapTerm1 (mapTermF (mapTerm (mapTerm f))) sort (term1 o args))) j)
      (λ j → joinFQ-astF (mapTerm1 (mapTermF (mapTerm f)) sort
        (mapTerm1 (mapTermF joinTerm) sort (term1 o args))) j)
      (λ i → joinFQ (mapTermF-joinTerm-nat f i sort (astF t)))
      (λ i → ast (mapTerm1 (joinTerm-nat f i) sort (mapTerm1 (λ sort₁ → joinFQ) sort t)))
    )
    (toPathP (isSetTerm _ _ _ _)) i j
joinTerm-nat f i sort (byAxiom axiom g j) =
  idfun
    (Square
      (λ j → (joinTerm sort ∘ mapTerm (mapTerm f) sort) (byAxiom axiom g j))
      (λ j → (mapTerm f sort ∘ joinTerm sort) (byAxiom axiom g j))
      (λ i → joinFQ (mapTermF-joinTerm-nat f i sort (mapTermF g sort (lhs axiom))))
      (λ i → joinFQ (mapTermF-joinTerm-nat f i sort (mapTermF g sort (rhs axiom))))
    )
    (toPathP (isSetTerm _ _ _ _)) i j
joinTerm-nat f i sort (isSetTerm t1 t2 et et' j k) = isSetTerm
  (joinTerm-nat f i sort t1)
  (joinTerm-nat f i sort t2)
  (λ k → joinTerm-nat f i sort (et k))
  (λ k → joinTerm-nat f i sort (et' k)) j k
mapTermF-joinTerm-nat f =
  (λ sort → mapTermF joinTerm sort ∘ mapTermF (mapTerm (mapTerm f)) sort)
    ≡⟨ sym (mapTermF-∘ joinTerm (mapTerm (mapTerm f))) ⟩
  mapTermF (λ sort → joinTerm sort ∘ mapTerm (mapTerm f) sort)
    ≡⟨ cong mapTermF (joinTerm-nat f) ⟩
  mapTermF (λ sort → mapTerm f sort ∘ joinTerm sort)
    ≡⟨ mapTermF-∘ (mapTerm f) joinTerm ⟩
  (λ sort → mapTermF (mapTerm f) sort ∘ mapTermF joinTerm sort) ∎

{-# TERMINATING #-}
joinTerm-lUnit : ∀ {X : MType} →
  (λ sort → joinTerm sort ∘ mapTerm pureTerm sort) ≡ λ (sort : Sort) → idfun (Term X sort)
mapTermF-joinTerm-lUnit : ∀ {X : MType} →
  (λ sort → mapTermF joinTerm sort ∘ mapTermF (mapTerm pureTerm) sort) ≡ λ (sort : Sort) → idfun (TermF (Term X) sort)
joinTerm-lUnit i sort (var x) = var x
joinTerm-lUnit i sort (ast t) = ast (mapTerm1 (joinTerm-lUnit i) sort t)
joinTerm-lUnit i sort (joinFQ t) = joinFQ (mapTermF-joinTerm-lUnit i sort t)
joinTerm-lUnit i sort (joinFQ-varF t j) =
  idfun
    (Square
      (λ j → (joinTerm sort ∘ mapTerm pureTerm sort) (joinFQ-varF t j))
      (λ j → joinFQ-varF t j)
      (λ i → joinFQ (varF (joinTerm-lUnit i sort t)))
      (λ i → joinTerm-lUnit i sort t)
    )
    (toPathP (isSetTerm _ _ _ _)) i j
joinTerm-lUnit i sort (joinFQ-astF t j) =
  idfun
    (Square
      (λ j → (joinTerm sort ∘ mapTerm pureTerm sort) (joinFQ-astF t j))
      (λ j → joinFQ-astF t j)
      (λ i → joinFQ (astF (mapTerm1 (mapTermF-joinTerm-lUnit i) sort t)))
      (λ i → ast (mapTerm1 (joinTerm-lUnit i) sort (mapTerm1 (λ sort₁ → joinFQ) sort t)))
    )
    (toPathP (isSetTerm _ _ _ _)) i j
joinTerm-lUnit i sort (byAxiom axiom f j) =
  idfun
    (Square
      (λ j → (joinTerm sort ∘ mapTerm pureTerm sort) (byAxiom axiom f j))
      (λ j → byAxiom axiom f j)
      (λ i → joinFQ (mapTermF-joinTerm-lUnit i sort (mapTermF f sort (lhs axiom))))
      (λ i → joinFQ (mapTermF-joinTerm-lUnit i sort (mapTermF f sort (rhs axiom))))
    )
    (toPathP (isSetTerm _ _ _ _)) i j
joinTerm-lUnit i sort (isSetTerm t1 t2 et et' j k) = isSetTerm
  (joinTerm-lUnit i sort t1)
  (joinTerm-lUnit i sort t2)
  (λ j → joinTerm-lUnit i sort (et j))
  (λ j → joinTerm-lUnit i sort (et' j)) j k
mapTermF-joinTerm-lUnit i sort (varF t) = varF (joinTerm-lUnit i sort t)
mapTermF-joinTerm-lUnit i sort (astF t) = astF (mapTerm1 (mapTermF-joinTerm-lUnit i) sort t)

{-# TERMINATING #-}
joinTerm-assoc : ∀ {X : MType} →
  (λ (sort : Sort) → joinTerm {X = X} sort ∘ mapTerm joinTerm sort) ≡ (λ sort → joinTerm sort ∘ joinTerm sort)
mapTermF-joinTerm-assoc : ∀ {X : MType} →
  (λ (sort : Sort) → mapTermF (joinTerm {X = X}) sort ∘ mapTermF (mapTerm joinTerm) sort)
  ≡ (λ sort → mapTermF joinTerm sort ∘ mapTermF joinTerm sort)
joinTerm-assoc i sort (var t) = joinTerm sort t
joinTerm-assoc i sort (ast t) = ast (mapTerm1 (joinTerm-assoc i) sort t)
joinTerm-assoc i sort (joinFQ t) = joinFQ (mapTermF-joinTerm-assoc i sort t)
joinTerm-assoc i sort (joinFQ-varF t j) =
  idfun
    (Square
      (λ j → (joinTerm sort ∘ mapTerm joinTerm sort) (joinFQ-varF t j))
      (λ j → (joinTerm sort ∘ joinTerm sort) (joinFQ-varF t j))
      (λ i → joinFQ (varF (joinTerm-assoc i sort t)))
      (λ i → joinTerm-assoc i sort t)
    )
    (toPathP (isSetTerm _ _ _ _)) i j
joinTerm-assoc i sort (joinFQ-astF t j) =
  idfun
    (Square
      (λ j → (joinTerm sort ∘ mapTerm joinTerm sort) (joinFQ-astF t j))
      (λ j → (joinTerm sort ∘ joinTerm sort) (joinFQ-astF t j))
      (λ i → joinFQ (astF (mapTerm1 (mapTermF-joinTerm-assoc i) sort t)))
      (λ i → ast (mapTerm1 (joinTerm-assoc i) sort (mapTerm1 (λ sort₁ → joinFQ) sort t)))
    )
    (toPathP (isSetTerm _ _ _ _)) i j
joinTerm-assoc i sort (byAxiom axiom f j) =
  idfun
    (Square
      (λ j → (joinTerm sort ∘ mapTerm joinTerm sort) (byAxiom axiom f j))
      (λ j → (joinTerm sort ∘ joinTerm sort) (byAxiom axiom f j))
      (λ i → joinFQ (mapTermF-joinTerm-assoc i sort (mapTermF f sort (lhs axiom))))
      (λ i → joinFQ (mapTermF-joinTerm-assoc i sort (mapTermF f sort (rhs axiom))))
    )
    (toPathP (isSetTerm _ _ _ _)) i j
joinTerm-assoc i sort (isSetTerm t1 t2 et et' j k) = isSetTerm
  (joinTerm-assoc i sort t1)
  (joinTerm-assoc i sort t2)
  (λ j → joinTerm-assoc i sort (et j))
  (λ j → joinTerm-assoc i sort (et' j)) j k
mapTermF-joinTerm-assoc i sort (varF t) = varF (joinTerm-assoc i sort t)
mapTermF-joinTerm-assoc i sort (astF t) = astF (mapTerm1 (mapTermF-joinTerm-assoc i) sort t)

-- Term as a monad
ismonadTerm : IsMonad ftrTerm
N-ob (η ismonadTerm) msetX = pureTerm
N-hom (η ismonadTerm) f = refl
N-ob (μ ismonadTerm) msetX = joinTerm
N-hom (μ ismonadTerm) {msetX}{msetY} f = joinTerm-nat f
idl-μ ismonadTerm = makeNatTransPathP F-rUnit (λ i → ftrTerm) refl
idr-μ ismonadTerm = makeNatTransPathP F-lUnit (λ i → ftrTerm) (funExt λ msetX → joinTerm-lUnit)
assoc-μ ismonadTerm = makeNatTransPathP F-assoc (λ i → ftrTerm) (funExt λ msetX → joinTerm-assoc)

monadTerm : Monad catMSet
monadTerm = ftrTerm , ismonadTerm

-- Models are Eilenberg-Moore algebras of monadTerm
catModel : Category ℓ-zero ℓ-zero
catModel = EMCategory monadTerm

Model : Type
Model = ob catModel

ModelHom : (mA mB : Model) → Type
ModelHom = Hom[_,_] catModel

-- Forgetful functor sending models to their carrier
ftrForgetModel : Functor catModel catMSet
ftrForgetModel = ForgetEMAlgebra monadTerm

-- Free model functor
ftrFreeModel : Functor catMSet catModel
ftrFreeModel = FreeEMAlgebra monadTerm

adjModel : ftrFreeModel ⊣ ftrForgetModel
adjModel = emAdjunction monadTerm

-- Recursion/folding (with metavariables) and properties

mFoldModel : (msetX : MSet) → (mA : Model)
  → catMSet [ msetX , F-ob ftrForgetModel mA ]
  → catModel [ F-ob ftrFreeModel msetX , mA ]
mFoldModel msetX mA = _♯ adjModel {c = msetX} {d = mA}

foldModel : (msetX : MSet) → (mA : Model)
  → catMSet [ msetX , F-ob ftrForgetModel mA ]
  → ∀ sort → Term (mtyp msetX) sort → typ (carrier (fst mA) sort)
foldModel msetX mA f = mFoldModel msetX mA f .carrierHom

mFoldModel-nat :  (msetX : MSet) → (mA mB : Model)
  → (mG : catModel [ mA , mB ])
  → (f : catMSet [ msetX , F-ob ftrForgetModel mA ])
  → mFoldModel msetX mB (_⋆_
      catMSet
      {x = msetX}
      {y = F-ob ftrForgetModel mA}
      {z = F-ob ftrForgetModel mB}
      f
      (F-hom ftrForgetModel {x = mA} {y = mB} mG)
    )
  ≡ _⋆_ catModel {x = F-ob ftrFreeModel msetX} {mA} {mB} (mFoldModel msetX mA f) mG
mFoldModel-nat msetX mA mB mG f =
  sym (adjNatInD' adjModel {c = msetX} {d = mA} {d' = mB} f mG)

foldModel-nat : (msetX : MSet) → (mA mB : Model)
  → (mG : catModel [ mA , mB ])
  → (f : catMSet [ msetX , F-ob ftrForgetModel mA ])
  → foldModel msetX mB (λ sort → F-hom ftrForgetModel {x = mA} {y = mB} mG sort ∘ f sort)
   ≡ (λ sort → F-hom ftrForgetModel {x = mA} {y = mB} mG sort ∘ foldModel msetX mA f sort)
foldModel-nat msetX mA mB mG f i = mFoldModel-nat msetX mA mB mG f i .carrierHom

mFoldModel-uniq : (msetX : MSet) → (mA : Model)
  → (f : catMSet [ msetX , F-ob ftrForgetModel mA ])
  → (mG : catModel [ F-ob ftrFreeModel msetX , mA ])
  → (λ sort → mG .carrierHom sort ∘ pureTerm sort) ≡ f
  → mFoldModel msetX mA f ≡ mG
mFoldModel-uniq msetX mA f mG ef =
  mFoldModel msetX mA f
    ≡⟨⟩
  _♯ adjModel {c = msetX} {d = mA} f
    ≡⟨ cong (_♯ adjModel {c = msetX} {d = mA}) (sym ef) ⟩
  _♯ adjModel {c = msetX} {d = mA} (λ sort → mG .carrierHom sort ∘ pureTerm sort)
    ≡⟨⟩
  _♯ adjModel {c = msetX} {d = mA} (_♭ adjModel {c = msetX} {d = mA} mG)
    ≡⟨ adjModel .adjIso {c = msetX} {d = mA} .leftInv mG ⟩
  mG ∎

foldModel-uniq : (msetX : MSet) → (mA : Model)
  → (f : catMSet [ msetX , F-ob ftrForgetModel mA ])
  → (mG : catModel [ F-ob ftrFreeModel msetX , mA ])
  → (λ sort → mG .carrierHom sort ∘ pureTerm sort) ≡ f
  → foldModel msetX mA f ≡ mG .carrierHom
foldModel-uniq msetX mA f mG ef i = mFoldModel-uniq msetX mA f mG ef i .carrierHom

foldModel-uniq2 : (msetX : MSet) → (mA : Model)
  → (mG mH : catModel [ F-ob ftrFreeModel msetX , mA ])
  → (λ (sort : Sort) → mG .carrierHom sort ∘ pureTerm sort)
   ≡ (λ (sort : Sort) → mH .carrierHom sort ∘ pureTerm sort)
  → mG .carrierHom ≡ mH .carrierHom
foldModel-uniq2 msetX mA mG mH e =
  mG .carrierHom
    ≡⟨ sym (foldModel-uniq msetX mA (λ sort → mG .carrierHom sort ∘ pureTerm sort) mG refl) ⟩
  foldModel msetX mA (λ sort → mG .carrierHom sort ∘ pureTerm sort)
    ≡⟨ foldModel-uniq msetX mA (λ sort → mG .carrierHom sort ∘ pureTerm sort) mH (sym e) ⟩
  mH .carrierHom ∎

-- catModel as a full subcategory of catModelF and catModel1
respectsEqTheoryF : ModelF → Type
respectsEqTheoryF mA = ∀ {sort} → (axiom : Axiom sort)
  → (f : ∀ sort' → mtyp (msetArity axiom) sort' → mtyp (mA .fst .carrier) sort')
  → (mA .fst .str sort ∘ mapTermF f sort) (lhs axiom)
   ≡ (mA .fst .str sort ∘ mapTermF f sort) (rhs axiom)

catModelFEq : Category ℓ-zero ℓ-zero
catModelFEq = FullSubcategory catModelF respectsEqTheoryF

ModelFEq : Type
ModelFEq = ob catModelFEq

ModelFEqHom : (mFEqA mFEqB : ModelFEq) → Type
ModelFEqHom = Hom[_,_] catModelFEq

respectsEqTheory1 : Model1 → Type
respectsEqTheory1 m1A = respectsEqTheoryF (model1toF m1A)

catModel1Eq : Category ℓ-zero ℓ-zero
catModel1Eq = FullSubcategory catModel1 respectsEqTheory1

Model1Eq : Type
Model1Eq = ob catModel1Eq

Model1EqHom : (m1EqA m1EqB : Model1Eq) → Type
Model1EqHom = Hom[_,_] catModel1Eq

{-# TERMINATING #-}
Model1Eq→IsTermAlgebra : (m1EqA : Model1Eq) → IsAlgebra ftrTerm (m1EqA .fst .carrier)
Model1Eq→IsTermAlgebra m1EqA@(algebra msetA α1 , respectsEqA) sort (var x) = x
Model1Eq→IsTermAlgebra m1EqA@(algebra msetA α1 , respectsEqA) sort (ast t) =
  α1 sort (mapTerm1 (Model1Eq→IsTermAlgebra m1EqA) sort t)
Model1Eq→IsTermAlgebra m1EqA@(algebra msetA α1 , respectsEqA) sort (joinFQ t) =
  αF sort (mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort t)
  where αF : IsAlgebra ftrTermF msetA
        αF = model1toF (algebra msetA α1) .fst .str
Model1Eq→IsTermAlgebra m1EqA@(algebra msetA α1 , respectsEqA) sort (joinFQ-varF t i) =
  Model1Eq→IsTermAlgebra m1EqA sort t
Model1Eq→IsTermAlgebra m1EqA@(algebra msetA α1 , respectsEqA) sort (joinFQ-astF t i) =
  α1 sort (mapTerm1 (Model1Eq→IsTermAlgebra m1EqA) sort (mapTerm1 (λ sort₁ → joinFQ) sort t))
Model1Eq→IsTermAlgebra m1EqA@(algebra msetA α1 , respectsEqA) sort (byAxiom axiom f i) =
  lemma2 i
  where αF : IsAlgebra ftrTermF msetA
        αF = model1toF (algebra msetA α1) .fst .str
        lemma : αF sort (mapTermF (λ sort' → Model1Eq→IsTermAlgebra m1EqA sort' ∘ f sort') sort (lhs axiom))
              ≡ αF sort (mapTermF (λ sort' → Model1Eq→IsTermAlgebra m1EqA sort' ∘ f sort') sort (rhs axiom))
        lemma = respectsEqA axiom λ sort' → Model1Eq→IsTermAlgebra m1EqA sort' ∘ f sort'
        lemma2 : αF sort (mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort (mapTermF f sort (lhs axiom)))
               ≡ αF sort (mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort (mapTermF f sort (rhs axiom)))
        lemma2 =
          αF sort (mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort (mapTermF f sort (lhs axiom)))
            ≡⟨ sym (cong (αF sort) (funExt⁻ (funExt⁻ (mapTermF-∘ (Model1Eq→IsTermAlgebra m1EqA) f) sort) (lhs axiom))) ⟩
          αF sort (mapTermF (λ sort' → Model1Eq→IsTermAlgebra m1EqA sort' ∘ f sort') sort (lhs axiom))
            ≡⟨ lemma ⟩
          αF sort (mapTermF (λ sort' → Model1Eq→IsTermAlgebra m1EqA sort' ∘ f sort') sort (rhs axiom))
            ≡⟨ cong (αF sort) (funExt⁻ (funExt⁻ (mapTermF-∘ (Model1Eq→IsTermAlgebra m1EqA) f) sort) (rhs axiom)) ⟩
          αF sort (mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort (mapTermF f sort (rhs axiom))) ∎
Model1Eq→IsTermAlgebra m1EqA@(algebra msetA α1 , respectsEqA) sort (isSetTerm t1 t2 et et' i j) = snd (msetA sort)
  (Model1Eq→IsTermAlgebra m1EqA sort t1)
  (Model1Eq→IsTermAlgebra m1EqA sort t2)
  (λ i → Model1Eq→IsTermAlgebra m1EqA sort (et i))
  (λ i → Model1Eq→IsTermAlgebra m1EqA sort (et' i)) i j

{-# TERMINATING #-}
Model1Eq→IsTermAlgebra-joinTerm : (m1EqA : Model1Eq)
  → (λ (sort : Sort) → Model1Eq→IsTermAlgebra m1EqA sort ∘ joinTerm sort)
  ≡ (λ (sort : Sort) → Model1Eq→IsTermAlgebra m1EqA sort ∘ mapTerm (Model1Eq→IsTermAlgebra m1EqA) sort)
mapTermF-Model1Eq→IsTermAlgebra-joinTerm : (m1EqA : Model1Eq)
  → (λ (sort : Sort) → mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort ∘ mapTermF joinTerm sort)
  ≡ (λ (sort : Sort) → mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort ∘ mapTermF (mapTerm (Model1Eq→IsTermAlgebra m1EqA)) sort)
Model1Eq→IsTermAlgebra-joinTerm m1EqA@(algebra msetA α1 , respectsEqA) i sort (var t) =
  Model1Eq→IsTermAlgebra m1EqA sort t
Model1Eq→IsTermAlgebra-joinTerm m1EqA@(algebra msetA α1 , respectsEqA) i sort (ast t) =
  α1 sort (mapTerm1 (Model1Eq→IsTermAlgebra-joinTerm m1EqA i) sort t)
Model1Eq→IsTermAlgebra-joinTerm m1EqA@(algebra msetA α1 , respectsEqA) i sort (joinFQ t) =
  αF sort (mapTermF-Model1Eq→IsTermAlgebra-joinTerm m1EqA i sort t)
  where αF : IsAlgebra ftrTermF msetA
        αF = model1toF (algebra msetA α1) .fst .str
Model1Eq→IsTermAlgebra-joinTerm m1EqA@(algebra msetA α1 , respectsEqA) i sort (joinFQ-varF t j) =
  idfun
    (Square
      (λ j → Model1Eq→IsTermAlgebra m1EqA sort (joinTerm sort t))
      (λ j → Model1Eq→IsTermAlgebra m1EqA sort
               (mapTerm (Model1Eq→IsTermAlgebra m1EqA) sort t))
      (λ i → αF sort (mapTermF-Model1Eq→IsTermAlgebra-joinTerm m1EqA i sort (varF t)))
      (λ i → Model1Eq→IsTermAlgebra-joinTerm m1EqA i sort t)
    ) (toPathP (snd (msetA sort) _ _ _ _)) i j
  where αF : IsAlgebra ftrTermF msetA
        αF = model1toF (algebra msetA α1) .fst .str
Model1Eq→IsTermAlgebra-joinTerm m1EqA@(algebra msetA α1 , respectsEqA) i sort (joinFQ-astF t j) =
  idfun
    (Square
      (λ j → (Model1Eq→IsTermAlgebra m1EqA sort ∘ joinTerm sort) (joinFQ-astF t j))
      (λ j → (Model1Eq→IsTermAlgebra m1EqA sort
                ∘ mapTerm (Model1Eq→IsTermAlgebra m1EqA) sort) (joinFQ-astF t j))
      (λ i → αF sort (mapTermF-Model1Eq→IsTermAlgebra-joinTerm m1EqA i sort (astF t)))
      (λ i → α1 sort (mapTerm1 (Model1Eq→IsTermAlgebra-joinTerm m1EqA i)
                 sort (mapTerm1 (λ sort₁ → joinFQ) sort t)))
    ) (toPathP (snd (msetA sort) _ _ _ _)) i j
  where αF : IsAlgebra ftrTermF msetA
        αF = model1toF (algebra msetA α1) .fst .str
Model1Eq→IsTermAlgebra-joinTerm m1EqA@(algebra msetA α1 , respectsEqA) i sort (byAxiom axiom f j) =
  idfun
    (Square
      (λ j → (Model1Eq→IsTermAlgebra m1EqA sort ∘ joinTerm sort) (byAxiom axiom f j))
      (λ j → (Model1Eq→IsTermAlgebra m1EqA sort
               ∘ mapTerm (Model1Eq→IsTermAlgebra m1EqA) sort) (byAxiom axiom f j))
      (λ i → αF sort (mapTermF-Model1Eq→IsTermAlgebra-joinTerm m1EqA i sort (mapTermF f sort (lhs axiom))))
      (λ i → αF sort (mapTermF-Model1Eq→IsTermAlgebra-joinTerm m1EqA i sort (mapTermF f sort (rhs axiom))))
    ) (toPathP (snd (msetA sort) _ _ _ _)) i j
  where αF : IsAlgebra ftrTermF msetA
        αF = model1toF (algebra msetA α1) .fst .str
Model1Eq→IsTermAlgebra-joinTerm m1EqA@(algebra msetA α1 , respectsEqA) i sort (isSetTerm t1 t2 et et' j k) = snd (msetA sort)
  (Model1Eq→IsTermAlgebra-joinTerm m1EqA i sort t1)
  (Model1Eq→IsTermAlgebra-joinTerm m1EqA i sort t2)
  (λ j → Model1Eq→IsTermAlgebra-joinTerm m1EqA i sort (et j))
  (λ j → Model1Eq→IsTermAlgebra-joinTerm m1EqA i sort (et' j)) j k
mapTermF-Model1Eq→IsTermAlgebra-joinTerm m1EqA =
  (λ sort → mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort ∘ mapTermF joinTerm sort)
    ≡⟨ sym (mapTermF-∘ (Model1Eq→IsTermAlgebra m1EqA) joinTerm) ⟩
  mapTermF (λ sort → Model1Eq→IsTermAlgebra m1EqA sort ∘ joinTerm sort)
    ≡⟨ cong mapTermF (Model1Eq→IsTermAlgebra-joinTerm m1EqA) ⟩
  mapTermF (λ sort → Model1Eq→IsTermAlgebra m1EqA sort ∘ mapTerm (Model1Eq→IsTermAlgebra m1EqA) sort)
    ≡⟨ mapTermF-∘ (Model1Eq→IsTermAlgebra m1EqA) (mapTerm (Model1Eq→IsTermAlgebra m1EqA)) ⟩
  (λ sort → mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort ∘ mapTermF (mapTerm (Model1Eq→IsTermAlgebra m1EqA)) sort) ∎

Model1Eq→IsTermEMAlgebra : (m1EqA : Model1Eq)
  → IsEMAlgebra monadTerm (algebra (m1EqA .fst .carrier) (Model1Eq→IsTermAlgebra m1EqA))
str-η (Model1Eq→IsTermEMAlgebra m1EqA@(algebra msetA α1 , respectsEqA)) = refl
str-μ (Model1Eq→IsTermEMAlgebra m1EqA@(algebra msetA α1 , respectsEqA)) = Model1Eq→IsTermAlgebra-joinTerm m1EqA

Model1Eq→Model : Model1Eq → Model
carrier (fst (Model1Eq→Model m1EqA@(algebra msetA α1 , respectsEqA))) = msetA
str (fst (Model1Eq→Model m1EqA@(algebra msetA α1 , respectsEqA))) = Model1Eq→IsTermAlgebra m1EqA
snd (Model1Eq→Model m1EqA@(algebra msetA α1 , respectsEqA)) = Model1Eq→IsTermEMAlgebra m1EqA

{-# TERMINATING #-}
ModelHom1Eq→IsTermAlgebraHom' : ∀ m1EqA m1EqB → (m1EqF : Model1EqHom m1EqA m1EqB) →
      (sort : Sort) (t : Term (mtyp (m1EqA .fst .carrier)) sort) →
      carrierHom m1EqF sort (Model1Eq→IsTermAlgebra m1EqA sort t)
      ≡ Model1Eq→IsTermAlgebra m1EqB sort (mapTerm (carrierHom m1EqF) sort t)

mapTermF-ModelHom1Eq→IsTermAlgebraHom' : ∀ m1EqA m1EqB → (m1EqF : Model1EqHom m1EqA m1EqB) →
      (sort : Sort) (t : TermF (Term (mtyp (m1EqA .fst .carrier))) sort) →
      carrierHom m1EqF sort (algStrFModel1 (m1EqA .fst) sort (mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort t))
      ≡ algStrFModel1 (m1EqB .fst) sort
        (mapTermF (Model1Eq→IsTermAlgebra m1EqB) sort (mapTermF (mapTerm (carrierHom m1EqF)) sort t))

ModelHom1Eq→IsTermAlgebraHom' m1EqA m1EqB m1EqF@(algebraHom f f-isalg1) sort (var x) = refl

ModelHom1Eq→IsTermAlgebraHom' m1EqA m1EqB m1EqF@(algebraHom f f-isalg1) sort (ast t) =
  f sort (str (fst m1EqA) sort (mapTerm1 (Model1Eq→IsTermAlgebra m1EqA) sort t))
    ≡⟨ funExt⁻ (funExt⁻ f-isalg1 sort) (mapTerm1 (Model1Eq→IsTermAlgebra m1EqA) sort t) ⟩
  str (fst m1EqB) sort (mapTerm1 f sort (mapTerm1 (Model1Eq→IsTermAlgebra m1EqA) sort t))
    ≡⟨ cong (str (fst m1EqB) sort) (funExt⁻ (funExt⁻ (cong mapTerm1 (
      (λ sort' → f sort' ∘ Model1Eq→IsTermAlgebra m1EqA sort')
        ≡⟨ (funExt λ sort' → funExt λ t' → ModelHom1Eq→IsTermAlgebraHom' m1EqA m1EqB m1EqF sort' t') ⟩
      (λ sort' → Model1Eq→IsTermAlgebra m1EqB sort' ∘ mapTerm f sort') ∎
    )) sort) t) ⟩
  str (fst m1EqB) sort (mapTerm1 (Model1Eq→IsTermAlgebra m1EqB) sort (mapTerm1 (mapTerm f) sort t)) ∎

ModelHom1Eq→IsTermAlgebraHom' m1EqA m1EqB m1EqF@(algebraHom f f-isalg1) sort (joinFQ t) i =
  mapTermF-ModelHom1Eq→IsTermAlgebraHom' m1EqA m1EqB m1EqF sort t i

ModelHom1Eq→IsTermAlgebraHom'
  m1EqA -- @(algebra msetA α1 , respectsEqA)
  m1EqB@(algebra msetB β1 , respectsEqB)
  m1EqF@(algebraHom f f-isalg1)
  sort (joinFQ-varF t j) i =
  -- PROBLEM HERE

  idfun
    (Square
      (λ j → f sort (Model1Eq→IsTermAlgebra
               m1EqA -- (algebra (carrier (fst m1EqA)) (str (fst m1EqA)) , snd m1EqA)
               sort t))
      (λ j → Model1Eq→IsTermAlgebra
               m1EqB -- (algebra msetB β1 , respectsEqB)
               sort (mapTerm f sort t))
      (λ i → mapTermF-ModelHom1Eq→IsTermAlgebraHom'
               m1EqA
               m1EqB -- (algebra msetB β1 , respectsEqB)
               m1EqF -- (algebraHom f f-isalg1)
               sort (varF t) i)
      (λ i → ModelHom1Eq→IsTermAlgebraHom'
               m1EqA
               m1EqB -- (algebra msetB β1 , respectsEqB)
               m1EqF -- (algebraHom f f-isalg1)
               sort t i)
    ) (toPathP (snd (msetB sort) _ _ _ _)) i j

ModelHom1Eq→IsTermAlgebraHom' m1EqA m1EqB@(algebra msetB β1 , respectsEqB) m1EqF@(algebraHom _ _) sort (joinFQ-astF t j) i =
  {!idfun
    (Square
      (λ j → {!!})
      (λ j → {!!})
      (λ i → {!!})
      (λ i → {!!})
    ) (toPathP (snd (msetB sort) _ _ _ _)) i j!}
ModelHom1Eq→IsTermAlgebraHom' m1EqA m1EqB@(algebra msetB β1 , respectsEqB) m1EqF@(algebraHom _ _) sort (byAxiom axiom g j) i =
  {!idfun
    (Square
      (λ j → {!!})
      (λ j → {!!})
      (λ i → {!!})
      (λ i → {!!})
    ) (toPathP (snd (msetB sort) _ _ _ _)) i j!}
ModelHom1Eq→IsTermAlgebraHom' m1EqA m1EqB@(algebra msetB β1 , respectsEqB) m1EqF@(algebraHom _ _) sort (isSetTerm t1 t2 et et' j k) i =
  {!!}


mapTermF-ModelHom1Eq→IsTermAlgebraHom'
  m1EqA@(algebra msetA α1 , respectsEqA)
  m1EqB@(algebra msetB β1 , respectsEqB)
  m1EqF@(algebraHom f f-isalg1) sort t =
    f sort (αF sort (mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort t))
      ≡⟨ funExt⁻ (funExt⁻ f-isalgF sort) (mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort t) ⟩
    βF sort (mapTermF f sort (mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort t))
      ≡⟨ cong (βF sort) (funExt⁻ (funExt⁻ (
        (λ sort' → mapTermF f sort' ∘ mapTermF (Model1Eq→IsTermAlgebra m1EqA) sort')
          ≡⟨ sym (mapTermF-∘ f (Model1Eq→IsTermAlgebra m1EqA)) ⟩
        mapTermF (λ sort₁ → f sort₁ ∘ Model1Eq→IsTermAlgebra (algebra msetA α1 , respectsEqA) sort₁)
          ≡⟨ cong mapTermF (funExt λ sort' → funExt λ t' → ModelHom1Eq→IsTermAlgebraHom' m1EqA m1EqB m1EqF sort' t') ⟩
        mapTermF (λ sort₁ → Model1Eq→IsTermAlgebra m1EqB sort₁ ∘ mapTerm f sort₁)
          ≡⟨ mapTermF-∘ (Model1Eq→IsTermAlgebra m1EqB) (mapTerm f) ⟩
        (λ sort' → mapTermF (Model1Eq→IsTermAlgebra m1EqB) sort' ∘ mapTermF (mapTerm f) sort') ∎
      ) sort) t) ⟩
    βF sort (mapTermF (Model1Eq→IsTermAlgebra m1EqB) sort (mapTermF (mapTerm f) sort t)) ∎
  where αF : IsAlgebra ftrTermF msetA
        αF = model1toF (algebra msetA α1) .fst .str
        βF : IsAlgebra ftrTermF msetB
        βF = model1toF (algebra msetB β1) .fst .str
        f-isalgF : IsAlgebraHom ftrTermF (algebra msetA αF) (algebra msetB βF) f
        f-isalgF = strHom (model1toF-hom m1EqF)

{-

ModelHom1Eq→IsTermAlgebraHom : ∀ m1EqA m1EqB → (m1EqF : Model1EqHom m1EqA m1EqB) →
      (λ (sort : Sort) (t : Term (mtyp (m1EqA .fst .carrier)) sort)
        → carrierHom m1EqF sort (Model1Eq→IsTermAlgebra m1EqA sort t))
      ≡
      (λ (sort : Sort) (t : Term (mtyp (m1EqA .fst .carrier)) sort)
        → Model1Eq→IsTermAlgebra m1EqB sort (mapTerm (carrierHom m1EqF) sort t))
ModelHom1Eq→IsTermAlgebraHom m1EqA m1EqB m1EqF i sort t =
  ModelHom1Eq→IsTermAlgebraHom' m1EqA m1EqB m1EqF sort t i

ModelHom1Eq→ModelHom : ∀ m1EqA m1EqB → Model1EqHom m1EqA m1EqB → ModelHom (Model1Eq→Model m1EqA) (Model1Eq→Model m1EqB)
carrierHom (ModelHom1Eq→ModelHom m1EqA m1EqB m1EqF) = carrierHom m1EqF
strHom (ModelHom1Eq→ModelHom m1EqA m1EqB m1EqF) = {!!}

ftrModel1Eq→Model : Functor catModel1Eq catModel
F-ob ftrModel1Eq→Model = Model1Eq→Model
F-hom ftrModel1Eq→Model {m1EqA} {m1EqB} = ModelHom1Eq→ModelHom m1EqA m1EqB
F-id ftrModel1Eq→Model = AlgebraHom≡ ftrTerm refl
F-seq ftrModel1Eq→Model f g = AlgebraHom≡ ftrTerm refl

-----

isoftrModelFEq→Model : P.PrecatIso (CatPrecategory ℓ-zero ℓ-zero) catModelFEq catModel
P≅.mor isoftrModelFEq→Model = {!!}
P≅.inv isoftrModelFEq→Model = {!!}
P≅.sec isoftrModelFEq→Model = {!!}
P≅.ret isoftrModelFEq→Model = {!!}

-- -}
