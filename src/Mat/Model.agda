{-# OPTIONS --cubical --type-in-type #-}

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Function
open import Cubical.Foundations.Isomorphism renaming (Iso to _≅_)
open import Cubical.Foundations.HLevels
open import Cubical.Data.List.FinData renaming (lookup to _!_)
open import Cubical.Data.Sigma
open import Cubical.Foundations.Structure hiding (str)
open import Cubical.Categories.Category
import Cubical.Categories.Category.Precategory as P
open import Cubical.Categories.Functor renaming (𝟙⟨_⟩ to funcId)
open import Cubical.Categories.NaturalTransformation
open import Cubical.Categories.Monad.Base
open import Cubical.Categories.Instances.FunctorAlgebras
open import Cubical.Categories.Instances.EilenbergMoore
open import Cubical.Categories.Instances.Categories
open import Cubical.Categories.Adjoint
open import Cubical.Categories.Constructions.FullSubcategory
open import Cubical.Categories.Limits.Initial

open import Mat.Signature
open import Mat.Free.Presentation
import Mat.Free.TermQ
import Mat.Free.Model
import Mat.TermQ
open import Mat.Presentation

-- TermQs of the MAT generated by a MAT presentation
module Mat.Model {sign : Signature} (mat : Mat sign) where

open Signature sign
open Mat
open FreeMat (getFreeMat mat)
open Mat.Free.TermQ (getFreeMat mat)
open Mat.Free.Model (getFreeMat mat)
open EqTheory (getEqTheory mat)
open Mat.TermQ mat

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
private
  module P≅ = P.PrecatIso

-- Models are Eilenberg-Moore algebras of monadTermQ
catModel : Category ℓ-zero ℓ-zero
catModel = EMCategory monadTermQ

Model : Type
Model = ob catModel

ModelHom : (mA mB : Model) → Type
ModelHom = Hom[_,_] catModel

-- Forgetful functor sending models to their carrier
ftrForgetModel : Functor catModel catMSet
ftrForgetModel = ForgetEMAlgebra monadTermQ

-- Free model functor
ftrFreeModel : Functor catMSet catModel
ftrFreeModel = FreeEMAlgebra monadTermQ

adjModel : ftrFreeModel ⊣ ftrForgetModel
adjModel = emAdjunction monadTermQ

-- Recursion/folding (with metavariables) and properties

mFoldModel : (msetX : MSet) → (mA : Model)
  → catMSet [ msetX , F-ob ftrForgetModel mA ]
  → catModel [ F-ob ftrFreeModel msetX , mA ]
mFoldModel msetX mA = _♯ adjModel {c = msetX} {d = mA}

foldModel : (msetX : MSet) → (mA : Model)
  → catMSet [ msetX , F-ob ftrForgetModel mA ]
  → ∀ sort → TermQ (mtyp msetX) sort → typ (carrier (fst mA) sort)
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
  → (λ sort → mG .carrierHom sort ∘ pureTermQ sort) ≡ f
  → mFoldModel msetX mA f ≡ mG
mFoldModel-uniq msetX mA f mG ef =
  mFoldModel msetX mA f
    ≡⟨⟩
  _♯ adjModel {c = msetX} {d = mA} f
    ≡⟨ cong (_♯ adjModel {c = msetX} {d = mA}) (sym ef) ⟩
  _♯ adjModel {c = msetX} {d = mA} (λ sort → mG .carrierHom sort ∘ pureTermQ sort)
    ≡⟨⟩
  _♯ adjModel {c = msetX} {d = mA} (_♭ adjModel {c = msetX} {d = mA} mG)
    ≡⟨ adjModel .adjIso {c = msetX} {d = mA} .leftInv mG ⟩
  mG ∎

foldModel-uniq : (msetX : MSet) → (mA : Model)
  → (f : catMSet [ msetX , F-ob ftrForgetModel mA ])
  → (mG : catModel [ F-ob ftrFreeModel msetX , mA ])
  → (λ sort → mG .carrierHom sort ∘ pureTermQ sort) ≡ f
  → foldModel msetX mA f ≡ mG .carrierHom
foldModel-uniq msetX mA f mG ef i = mFoldModel-uniq msetX mA f mG ef i .carrierHom

foldModel-uniq2 : (msetX : MSet) → (mA : Model)
  → (mG mH : catModel [ F-ob ftrFreeModel msetX , mA ])
  → (λ (sort : Sort) → mG .carrierHom sort ∘ pureTermQ sort)
   ≡ (λ (sort : Sort) → mH .carrierHom sort ∘ pureTermQ sort)
  → mG .carrierHom ≡ mH .carrierHom
foldModel-uniq2 msetX mA mG mH e =
  mG .carrierHom
    ≡⟨ sym (foldModel-uniq msetX mA (λ sort → mG .carrierHom sort ∘ pureTermQ sort) mG refl) ⟩
  foldModel msetX mA (λ sort → mG .carrierHom sort ∘ pureTermQ sort)
    ≡⟨ foldModel-uniq msetX mA (λ sort → mG .carrierHom sort ∘ pureTermQ sort) mH (sym e) ⟩
  mH .carrierHom ∎

-- catModel as a full subcategory of catModelF and catModel1

-- catModelFEq and catModel1Eq
respectsEqTheoryF : ModelF → Type
respectsEqTheoryF mA = ∀ {sort} → (axiom : Axiom sort)
  → (f : ∀ sort' → mtyp (msetArity axiom) sort' → mtyp (mA .fst .carrier) sort')
  → (mA .fst .str sort ∘ mapTermF f sort) (lhs axiom)
   ≡ (mA .fst .str sort ∘ mapTermF f sort) (rhs axiom)

isProp-respectsEqTheoryF : (mFA : ModelF) → isProp (respectsEqTheoryF mFA)
isProp-respectsEqTheoryF mFA =
  isPropImplicitΠ λ sort → isPropΠ λ axiom → isPropΠ λ f →
    mFA .fst .carrier sort .snd _ _

catModelFEq : Category ℓ-zero ℓ-zero
catModelFEq = FullSubcategory catModelF respectsEqTheoryF

ModelFEq : Type
ModelFEq = ob catModelFEq

ModelFEqHom : (mFEqA mFEqB : ModelFEq) → Type
ModelFEqHom = Hom[_,_] catModelFEq

respectsEqTheory1 : Model1 → Type
respectsEqTheory1 m1A = respectsEqTheoryF (model1→F m1A)

isProp-respectsEqTheory1 : (m1A : Model1) → isProp (respectsEqTheory1 m1A)
isProp-respectsEqTheory1 m1A = isProp-respectsEqTheoryF (model1→F m1A)

catModel1Eq : Category ℓ-zero ℓ-zero
catModel1Eq = FullSubcategory catModel1 respectsEqTheory1

Model1Eq : Type
Model1Eq = ob catModel1Eq

Model1EqHom : (m1EqA m1EqB : Model1Eq) → Type
Model1EqHom = Hom[_,_] catModel1Eq

--------------

respectsEqTheory1→F : (m1A : Model1) → respectsEqTheory1 m1A → respectsEqTheoryF (model1→F m1A)
respectsEqTheory1→F m1A respectsEqTheory1A = respectsEqTheory1A

ftrModel1Eq→FEq : Functor catModel1Eq catModelFEq
ftrModel1Eq→FEq = MapFullSubcategory
  catModel1 respectsEqTheory1
  catModelF respectsEqTheoryF
  ftrModel1→F respectsEqTheory1→F

model1Eq→FEq : Model1Eq → ModelFEq
model1Eq→FEq = F-ob ftrModel1Eq→FEq

respectsEqTheoryF→1 : (mFA : ModelF) → respectsEqTheoryF mFA → respectsEqTheory1 (modelF→1 mFA)
respectsEqTheoryF→1 mFA respectsEqTheoryFA = subst
  respectsEqTheoryF
  (cong (λ F → F-ob F mFA) (sym ftrModelF→1→F))
  respectsEqTheoryFA

ftrModelFEq→1Eq : Functor catModelFEq catModel1Eq
ftrModelFEq→1Eq = MapFullSubcategory
  catModelF respectsEqTheoryF
  catModel1 respectsEqTheory1
  ftrModelF→1 respectsEqTheoryF→1

modelFEq→1Eq : ModelFEq → Model1Eq
modelFEq→1Eq = F-ob ftrModelFEq→1Eq

ftrModel1Eq→FEq→1Eq : funcComp ftrModelFEq→1Eq ftrModel1Eq→FEq ≡ funcId catModel1Eq
ftrModel1Eq→FEq→1Eq =
  funcComp ftrModelFEq→1Eq ftrModel1Eq→FEq
    ≡⟨ sym (MapFullSubcategory-seq _ _ _ _ _ _ _ _ _ _) ⟩
  MapFullSubcategory
      catModel1 respectsEqTheory1
      catModel1 respectsEqTheory1
      (funcComp ftrModelF→1 ftrModel1→F)
      (λ c p → respectsEqTheoryF→1 (F-ob ftrModel1→F c) (respectsEqTheory1→F c p))
    ≡⟨ cong₂ (MapFullSubcategory catModel1 respectsEqTheory1 catModel1 respectsEqTheory1)
         ftrModel1→F→1
         (toPathP (funExt λ m1A → funExt λ respectsEqTheory1A → isProp-respectsEqTheory1 m1A _ _))
    ⟩
  MapFullSubcategory catModel1 respectsEqTheory1 catModel1 respectsEqTheory1 (funcId catModel1) (λ c p → p)
    ≡⟨ MapFullSubcategory-id _ _ ⟩
  funcId catModel1Eq ∎

ftrModelFEq→1Eq→FEq : funcComp ftrModel1Eq→FEq ftrModelFEq→1Eq ≡ funcId catModelFEq
ftrModelFEq→1Eq→FEq =
  funcComp ftrModel1Eq→FEq ftrModelFEq→1Eq
    ≡⟨ sym (MapFullSubcategory-seq _ _ _ _ _ _ _ _ _ _) ⟩
  MapFullSubcategory
      catModelF respectsEqTheoryF
      catModelF respectsEqTheoryF
      (funcComp ftrModel1→F ftrModelF→1)
      (λ c p → respectsEqTheory1→F (F-ob ftrModelF→1 c) (respectsEqTheoryF→1 c p))
    ≡⟨ cong₂ (MapFullSubcategory catModelF respectsEqTheoryF catModelF respectsEqTheoryF)
         ftrModelF→1→F
         (toPathP (funExt λ mFA → funExt λ respectsEqTheoryFA → isProp-respectsEqTheoryF mFA _ _))
    ⟩
  MapFullSubcategory catModelF respectsEqTheoryF catModelF respectsEqTheoryF (funcId catModelF) (λ c p → p)
    ≡⟨ MapFullSubcategory-id _ _ ⟩
  funcId catModelFEq ∎

isoftrModel1Eq≅FEq : P.PrecatIso (CatPrecategory ℓ-zero ℓ-zero) catModel1Eq catModelFEq
P≅.mor isoftrModel1Eq≅FEq = ftrModel1Eq→FEq
P≅.inv isoftrModel1Eq≅FEq = ftrModelFEq→1Eq
P≅.sec isoftrModel1Eq≅FEq = ftrModelFEq→1Eq→FEq
P≅.ret isoftrModel1Eq≅FEq = ftrModel1Eq→FEq→1Eq

--------------

-- catModel1Eq → catModel

{-# TERMINATING #-}
model1Eq→Q-algStr : (m1EqA : Model1Eq) → IsAlgebra ftrTermQ (m1EqA .fst .carrier)
model1Eq→Q-algStr m1EqA@(algebra msetA α1 , respectsEqA) sort (var x) = x
model1Eq→Q-algStr m1EqA@(algebra msetA α1 , respectsEqA) sort (ast t) =
  α1 sort (mapTerm1 (model1Eq→Q-algStr m1EqA) sort t)
model1Eq→Q-algStr m1EqA@(algebra msetA α1 , respectsEqA) sort (joinFQ t) =
  αF sort (mapTermF (model1Eq→Q-algStr m1EqA) sort t)
  where αF : IsAlgebra ftrTermF msetA
        αF = model1→F (algebra msetA α1) .fst .str
model1Eq→Q-algStr m1EqA@(algebra msetA α1 , respectsEqA) sort (joinFQ-varF t i) =
  model1Eq→Q-algStr m1EqA sort t
model1Eq→Q-algStr m1EqA@(algebra msetA α1 , respectsEqA) sort (joinFQ-astF t i) =
  α1 sort (mapTerm1 (model1Eq→Q-algStr m1EqA) sort (mapTerm1 (λ sort₁ → joinFQ) sort t))
model1Eq→Q-algStr m1EqA@(algebra msetA α1 , respectsEqA) sort (byAxiom axiom f i) =
  lemma2 i
  where αF : IsAlgebra ftrTermF msetA
        αF = model1→F (algebra msetA α1) .fst .str
        lemma : αF sort (mapTermF (λ sort' → model1Eq→Q-algStr m1EqA sort' ∘ f sort') sort (lhs axiom))
              ≡ αF sort (mapTermF (λ sort' → model1Eq→Q-algStr m1EqA sort' ∘ f sort') sort (rhs axiom))
        lemma = respectsEqA axiom λ sort' → model1Eq→Q-algStr m1EqA sort' ∘ f sort'
        lemma2 : αF sort (mapTermF (model1Eq→Q-algStr m1EqA) sort (mapTermF f sort (lhs axiom)))
               ≡ αF sort (mapTermF (model1Eq→Q-algStr m1EqA) sort (mapTermF f sort (rhs axiom)))
        lemma2 =
          αF sort (mapTermF (model1Eq→Q-algStr m1EqA) sort (mapTermF f sort (lhs axiom)))
            ≡⟨ sym (cong (αF sort) (funExt⁻ (funExt⁻ (mapTermF-∘ (model1Eq→Q-algStr m1EqA) f) sort) (lhs axiom))) ⟩
          αF sort (mapTermF (λ sort' → model1Eq→Q-algStr m1EqA sort' ∘ f sort') sort (lhs axiom))
            ≡⟨ lemma ⟩
          αF sort (mapTermF (λ sort' → model1Eq→Q-algStr m1EqA sort' ∘ f sort') sort (rhs axiom))
            ≡⟨ cong (αF sort) (funExt⁻ (funExt⁻ (mapTermF-∘ (model1Eq→Q-algStr m1EqA) f) sort) (rhs axiom)) ⟩
          αF sort (mapTermF (model1Eq→Q-algStr m1EqA) sort (mapTermF f sort (rhs axiom))) ∎
model1Eq→Q-algStr m1EqA@(algebra msetA α1 , respectsEqA) sort (isSetTermQ t1 t2 et et' i j) = snd (msetA sort)
  (model1Eq→Q-algStr m1EqA sort t1)
  (model1Eq→Q-algStr m1EqA sort t2)
  (λ i → model1Eq→Q-algStr m1EqA sort (et i))
  (λ i → model1Eq→Q-algStr m1EqA sort (et' i)) i j

{-# TERMINATING #-}
model1Eq→Q-algStr-joinTermQ : (m1EqA : Model1Eq)
  → (λ (sort : Sort) → model1Eq→Q-algStr m1EqA sort ∘ joinTermQ sort)
  ≡ (λ (sort : Sort) → model1Eq→Q-algStr m1EqA sort ∘ mapTermQ (model1Eq→Q-algStr m1EqA) sort)
mapTermF-model1Eq→Q-algStr-joinTermQ : (m1EqA : Model1Eq)
  → (λ (sort : Sort) → mapTermF (model1Eq→Q-algStr m1EqA) sort ∘ mapTermF joinTermQ sort)
  ≡ (λ (sort : Sort) → mapTermF (model1Eq→Q-algStr m1EqA) sort ∘ mapTermF (mapTermQ (model1Eq→Q-algStr m1EqA)) sort)
model1Eq→Q-algStr-joinTermQ m1EqA@(algebra msetA α1 , respectsEqA) i sort (var t) =
  model1Eq→Q-algStr m1EqA sort t
model1Eq→Q-algStr-joinTermQ m1EqA@(algebra msetA α1 , respectsEqA) i sort (ast t) =
  α1 sort (mapTerm1 (model1Eq→Q-algStr-joinTermQ m1EqA i) sort t)
model1Eq→Q-algStr-joinTermQ m1EqA@(algebra msetA α1 , respectsEqA) i sort (joinFQ t) =
  αF sort (mapTermF-model1Eq→Q-algStr-joinTermQ m1EqA i sort t)
  where αF : IsAlgebra ftrTermF msetA
        αF = model1→F (algebra msetA α1) .fst .str
model1Eq→Q-algStr-joinTermQ m1EqA@(algebra msetA α1 , respectsEqA) i sort (joinFQ-varF t j) =
  idfun
    (Square
      (λ j → model1Eq→Q-algStr m1EqA sort (joinTermQ sort t))
      (λ j → model1Eq→Q-algStr m1EqA sort
               (mapTermQ (model1Eq→Q-algStr m1EqA) sort t))
      (λ i → αF sort (mapTermF-model1Eq→Q-algStr-joinTermQ m1EqA i sort (varF t)))
      (λ i → model1Eq→Q-algStr-joinTermQ m1EqA i sort t)
    ) (toPathP (snd (msetA sort) _ _ _ _)) i j
  where αF : IsAlgebra ftrTermF msetA
        αF = model1→F (algebra msetA α1) .fst .str
model1Eq→Q-algStr-joinTermQ m1EqA@(algebra msetA α1 , respectsEqA) i sort (joinFQ-astF t j) =
  idfun
    (Square
      (λ j → (model1Eq→Q-algStr m1EqA sort ∘ joinTermQ sort) (joinFQ-astF t j))
      (λ j → (model1Eq→Q-algStr m1EqA sort
                ∘ mapTermQ (model1Eq→Q-algStr m1EqA) sort) (joinFQ-astF t j))
      (λ i → αF sort (mapTermF-model1Eq→Q-algStr-joinTermQ m1EqA i sort (astF t)))
      (λ i → α1 sort (mapTerm1 (model1Eq→Q-algStr-joinTermQ m1EqA i)
                 sort (mapTerm1 (λ sort₁ → joinFQ) sort t)))
    ) (toPathP (snd (msetA sort) _ _ _ _)) i j
  where αF : IsAlgebra ftrTermF msetA
        αF = model1→F (algebra msetA α1) .fst .str
model1Eq→Q-algStr-joinTermQ m1EqA@(algebra msetA α1 , respectsEqA) i sort (byAxiom axiom f j) =
  idfun
    (Square
      (λ j → (model1Eq→Q-algStr m1EqA sort ∘ joinTermQ sort) (byAxiom axiom f j))
      (λ j → (model1Eq→Q-algStr m1EqA sort
               ∘ mapTermQ (model1Eq→Q-algStr m1EqA) sort) (byAxiom axiom f j))
      (λ i → αF sort (mapTermF-model1Eq→Q-algStr-joinTermQ m1EqA i sort (mapTermF f sort (lhs axiom))))
      (λ i → αF sort (mapTermF-model1Eq→Q-algStr-joinTermQ m1EqA i sort (mapTermF f sort (rhs axiom))))
    ) (toPathP (snd (msetA sort) _ _ _ _)) i j
  where αF : IsAlgebra ftrTermF msetA
        αF = model1→F (algebra msetA α1) .fst .str
model1Eq→Q-algStr-joinTermQ m1EqA@(algebra msetA α1 , respectsEqA) i sort (isSetTermQ t1 t2 et et' j k) = snd (msetA sort)
  (model1Eq→Q-algStr-joinTermQ m1EqA i sort t1)
  (model1Eq→Q-algStr-joinTermQ m1EqA i sort t2)
  (λ j → model1Eq→Q-algStr-joinTermQ m1EqA i sort (et j))
  (λ j → model1Eq→Q-algStr-joinTermQ m1EqA i sort (et' j)) j k
mapTermF-model1Eq→Q-algStr-joinTermQ m1EqA =
  (λ sort → mapTermF (model1Eq→Q-algStr m1EqA) sort ∘ mapTermF joinTermQ sort)
    ≡⟨ sym (mapTermF-∘ (model1Eq→Q-algStr m1EqA) joinTermQ) ⟩
  mapTermF (λ sort → model1Eq→Q-algStr m1EqA sort ∘ joinTermQ sort)
    ≡⟨ cong mapTermF (model1Eq→Q-algStr-joinTermQ m1EqA) ⟩
  mapTermF (λ sort → model1Eq→Q-algStr m1EqA sort ∘ mapTermQ (model1Eq→Q-algStr m1EqA) sort)
    ≡⟨ mapTermF-∘ (model1Eq→Q-algStr m1EqA) (mapTermQ (model1Eq→Q-algStr m1EqA)) ⟩
  (λ sort → mapTermF (model1Eq→Q-algStr m1EqA) sort ∘ mapTermF (mapTermQ (model1Eq→Q-algStr m1EqA)) sort) ∎

model1Eq→Q-isEMAlgebra : (m1EqA : Model1Eq)
  → IsEMAlgebra monadTermQ (algebra (m1EqA .fst .carrier) (model1Eq→Q-algStr m1EqA))
str-η (model1Eq→Q-isEMAlgebra m1EqA@(algebra msetA α1 , respectsEqA)) = refl
str-μ (model1Eq→Q-isEMAlgebra m1EqA@(algebra msetA α1 , respectsEqA)) = model1Eq→Q-algStr-joinTermQ m1EqA

model1Eq→Q : Model1Eq → Model
carrier (fst (model1Eq→Q m1EqA@(algebra msetA α1 , respectsEqA))) = msetA
str (fst (model1Eq→Q m1EqA@(algebra msetA α1 , respectsEqA))) = model1Eq→Q-algStr m1EqA
snd (model1Eq→Q m1EqA@(algebra msetA α1 , respectsEqA)) = model1Eq→Q-isEMAlgebra m1EqA

{-# TERMINATING #-}
ModelHom1Eq→IsTermQAlgebraHom' : ∀ m1EqA m1EqB → (m1EqF : Model1EqHom m1EqA m1EqB) →
      (sort : Sort) (t : TermQ (mtyp (m1EqA .fst .carrier)) sort) →
      carrierHom m1EqF sort (model1Eq→Q-algStr m1EqA sort t)
      ≡ model1Eq→Q-algStr m1EqB sort (mapTermQ (carrierHom m1EqF) sort t)
mapTermF-ModelHom1Eq→IsTermQAlgebraHom' : ∀ m1EqA m1EqB → (m1EqF : Model1EqHom m1EqA m1EqB) →
      (sort : Sort) (t : TermF (TermQ (mtyp (m1EqA .fst .carrier))) sort) →
      carrierHom m1EqF sort (model1→F-algStr (m1EqA .fst) sort (mapTermF (model1Eq→Q-algStr m1EqA) sort t))
      ≡ model1→F-algStr (m1EqB .fst) sort
        (mapTermF (model1Eq→Q-algStr m1EqB) sort (mapTermF (mapTermQ (carrierHom m1EqF)) sort t))
ModelHom1Eq→IsTermQAlgebraHom' m1EqA m1EqB m1EqF@(algebraHom f f-isalg1) sort (var x) = refl
ModelHom1Eq→IsTermQAlgebraHom' m1EqA m1EqB m1EqF@(algebraHom f f-isalg1) sort (ast t) =
  f sort (str (fst m1EqA) sort (mapTerm1 (model1Eq→Q-algStr m1EqA) sort t))
    ≡⟨ funExt⁻ (funExt⁻ f-isalg1 sort) (mapTerm1 (model1Eq→Q-algStr m1EqA) sort t) ⟩
  str (fst m1EqB) sort (mapTerm1 f sort (mapTerm1 (model1Eq→Q-algStr m1EqA) sort t))
    ≡⟨ cong (str (fst m1EqB) sort) (funExt⁻ (funExt⁻ (cong mapTerm1 (
      (λ sort' → f sort' ∘ model1Eq→Q-algStr m1EqA sort')
        ≡⟨ (funExt λ sort' → funExt λ t' → ModelHom1Eq→IsTermQAlgebraHom' m1EqA m1EqB m1EqF sort' t') ⟩
      (λ sort' → model1Eq→Q-algStr m1EqB sort' ∘ mapTermQ f sort') ∎
    )) sort) t) ⟩
  str (fst m1EqB) sort (mapTerm1 (model1Eq→Q-algStr m1EqB) sort (mapTerm1 (mapTermQ f) sort t)) ∎
ModelHom1Eq→IsTermQAlgebraHom' m1EqA m1EqB m1EqF sort (joinFQ t) i =
  mapTermF-ModelHom1Eq→IsTermQAlgebraHom' m1EqA m1EqB m1EqF sort t i
-- The following all follows from Sethood but there seems to be a de Bruijn error in agda-cubical?
ModelHom1Eq→IsTermQAlgebraHom'
  m1EqA@(algebra msetA α1 , respectsEqA)
  m1EqB@(algebra msetB β1 , respectsEqB)
  m1EqF@(algebraHom f f-isalg1) sort (joinFQ-varF t j) i =
  {!idfun
    (Square
      (λ j → f sort
         (model1Eq→Q-algStr (algebra msetA α1 , respectsEqA) sort t))
      (λ j → model1Eq→Q-algStr (algebra msetB β1 , respectsEqB)
         sort (mapTermQ f sort t))
      (λ i → mapTermF-ModelHom1Eq→IsTermQAlgebraHom'
         (algebra msetA α1 , respectsEqA) (algebra msetB β1 , respectsEqB)
         (algebraHom f f-isalg1) sort (varF t) {!i!})
      (λ i → ModelHom1Eq→IsTermQAlgebraHom'
         (algebra msetA α1 , respectsEqA) (algebra msetB β1 , respectsEqB)
         (algebraHom f f-isalg1) sort t i)
    ) (toPathP (snd (msetB sort) _ _ _ _)) i j!}
ModelHom1Eq→IsTermQAlgebraHom' m1EqA m1EqB@(algebra msetB β1 , respectsEqB) m1EqF sort (joinFQ-astF t j) i =
  {!idfun
    (Square
      (λ j → {!!})
      (λ j → {!!})
      (λ i → {!!})
      (λ i → {!!})
    ) (toPathP (snd (msetB sort) _ _ _ _)) i j!}
ModelHom1Eq→IsTermQAlgebraHom' m1EqA m1EqB@(algebra msetB β1 , respectsEqB) m1EqF sort (byAxiom axiom g j) i =
  {!idfun
    (Square
      (λ j → {!!})
      (λ j → {!!})
      (λ i → {!!})
      (λ i → {!!})
    ) (toPathP (snd (msetB sort) _ _ _ _)) i j!}
ModelHom1Eq→IsTermQAlgebraHom' m1EqA m1EqB@(algebra msetB β1 , respectsEqB) m1EqF sort (isSetTermQ t1 t2 et et' j k) i =
  {!snd (msetB sort)
    ?
    ?
    ?
    ? j k!}
mapTermF-ModelHom1Eq→IsTermQAlgebraHom'
  m1EqA@(algebra msetA α1 , respectsEqA)
  m1EqB@(algebra msetB β1 , respectsEqB)
  m1EqF@(algebraHom f f-isalg1) sort t =
    f sort (αF sort (mapTermF (model1Eq→Q-algStr m1EqA) sort t))
      ≡⟨ funExt⁻ (funExt⁻ f-isalgF sort) (mapTermF (model1Eq→Q-algStr m1EqA) sort t) ⟩
    βF sort (mapTermF f sort (mapTermF (model1Eq→Q-algStr m1EqA) sort t))
      ≡⟨ cong (βF sort) (funExt⁻ (funExt⁻ (
        (λ sort' → mapTermF f sort' ∘ mapTermF (model1Eq→Q-algStr m1EqA) sort')
          ≡⟨ sym (mapTermF-∘ f (model1Eq→Q-algStr m1EqA)) ⟩
        mapTermF (λ sort₁ → f sort₁ ∘ model1Eq→Q-algStr (algebra msetA α1 , respectsEqA) sort₁)
          ≡⟨ cong mapTermF (funExt λ sort' → funExt λ t' → ModelHom1Eq→IsTermQAlgebraHom' m1EqA m1EqB m1EqF sort' t') ⟩
        mapTermF (λ sort₁ → model1Eq→Q-algStr m1EqB sort₁ ∘ mapTermQ f sort₁)
          ≡⟨ mapTermF-∘ (model1Eq→Q-algStr m1EqB) (mapTermQ f) ⟩
        (λ sort' → mapTermF (model1Eq→Q-algStr m1EqB) sort' ∘ mapTermF (mapTermQ f) sort') ∎
      ) sort) t) ⟩
    βF sort (mapTermF (model1Eq→Q-algStr m1EqB) sort (mapTermF (mapTermQ f) sort t)) ∎
  where αF : IsAlgebra ftrTermF msetA
        αF = model1→F (algebra msetA α1) .fst .str
        βF : IsAlgebra ftrTermF msetB
        βF = model1→F (algebra msetB β1) .fst .str
        f-isalgF : IsAlgebraHom ftrTermF (algebra msetA αF) (algebra msetB βF) f
        f-isalgF = strHom (model1→F-hom m1EqF)

{-

  {!!}
    ≡⟨ {!!} ⟩
  {!!}
-}

ModelHom1Eq→IsTermQAlgebraHom : ∀ m1EqA m1EqB → (m1EqF : Model1EqHom m1EqA m1EqB) →
      (λ (sort : Sort) (t : TermQ (mtyp (m1EqA .fst .carrier)) sort)
        → carrierHom m1EqF sort (model1Eq→Q-algStr m1EqA sort t))
      ≡
      (λ (sort : Sort) (t : TermQ (mtyp (m1EqA .fst .carrier)) sort)
        → model1Eq→Q-algStr m1EqB sort (mapTermQ (carrierHom m1EqF) sort t))
ModelHom1Eq→IsTermQAlgebraHom m1EqA m1EqB m1EqF i sort t =
  ModelHom1Eq→IsTermQAlgebraHom' m1EqA m1EqB m1EqF sort t i

ModelHom1Eq→ModelHom : ∀ m1EqA m1EqB → Model1EqHom m1EqA m1EqB → ModelHom (model1Eq→Q m1EqA) (model1Eq→Q m1EqB)
carrierHom (ModelHom1Eq→ModelHom m1EqA m1EqB m1EqF) = carrierHom m1EqF
strHom (ModelHom1Eq→ModelHom m1EqA m1EqB m1EqF) = ModelHom1Eq→IsTermQAlgebraHom m1EqA m1EqB m1EqF

ftrModel1Eq→Q : Functor catModel1Eq catModel
F-ob ftrModel1Eq→Q = model1Eq→Q
F-hom ftrModel1Eq→Q {m1EqA} {m1EqB} = ModelHom1Eq→ModelHom m1EqA m1EqB
F-id ftrModel1Eq→Q = AlgebraHom≡ ftrTermQ refl
F-seq ftrModel1Eq→Q f g = AlgebraHom≡ ftrTermQ refl

---------

-- catModel → catModelFEq

ftrModelQ→F : Functor catModel catModelF
ftrModelQ→F = EMFunctor monadTermF→Q

modelQ→F : Model → ModelF
modelQ→F = F-ob ftrModelQ→F

modelQ→F-respectsEqTheoryF : (mA : Model) → respectsEqTheoryF (modelQ→F mA)
modelQ→F-respectsEqTheoryF mA@(algebra msetA αQ , isEMA) {sort} axiom f = cong (αQ sort) (
  termF→Q sort (mapTermF f sort (lhs axiom))
    ≡⟨ sym (funExt⁻ (funExt⁻ lemma sort) (lhs axiom)) ⟩
  joinFQ (mapTermF (λ sort' x → var (f sort' x)) sort (lhs axiom))
    ≡⟨ modelQ→F-respectsEqTheoryF' ⟩
  joinFQ (mapTermF (λ sort' x → var (f sort' x)) sort (rhs axiom))
    ≡⟨ funExt⁻ (funExt⁻ lemma sort) (rhs axiom) ⟩
  termF→Q sort (mapTermF f sort (rhs axiom)) ∎
  )
  where modelQ→F-respectsEqTheoryF' : joinFQ (mapTermF (λ sort' x → pureTermQ sort' (f sort' x)) sort (lhs axiom))
                                     ≡ joinFQ (mapTermF (λ sort' x → pureTermQ sort' (f sort' x)) sort (rhs axiom))
        modelQ→F-respectsEqTheoryF' = byAxiom axiom (λ sort' → pureTermQ sort' ∘ f sort')
        lemma : (λ (sort : Sort) → joinFQ ∘ mapTermF (λ sort' x → pureTermQ sort' (f sort' x)) sort)
              ≡ (λ (sort : Sort) → termF→Q sort ∘ mapTermF f sort)
        lemma =
          (λ sort → joinFQ ∘ mapTermF (λ sort' x → pureTermQ sort' (f sort' x)) sort)
            ≡⟨ (funExt λ sort → cong (joinFQ ∘_) (funExt⁻ (mapTermF-∘ pureTermQ f) sort)) ⟩
          (λ sort → joinFQ ∘ mapTermF pureTermQ sort ∘ mapTermF f sort)
            ≡⟨ (funExt λ sort → cong (_∘ mapTermF f sort) (funExt⁻ joinFQ-mapTermF-pureTermQ sort)) ⟩
          (λ sort → termF→Q sort ∘ mapTermF f sort) ∎

ftrModelQ→FEq : Functor catModel catModelFEq
ftrModelQ→FEq = ToFullSubcategory catModel catModelF respectsEqTheoryF ftrModelQ→F modelQ→F-respectsEqTheoryF

modelQ→FEq : Model → ModelFEq
modelQ→FEq = F-ob ftrModelQ→FEq

---------

{-# TERMINATING #-}
model1Eq→F→Q-algStr : (m1Eq : Model1Eq)
  → (λ (sort : Sort) → model1Eq→Q-algStr m1Eq sort ∘ termF→Q sort)
   ≡ (λ (sort : Sort) → model1→F-algStr (fst m1Eq) sort)
model1Eq→F→Q-algStr m1Eq@(algebra msetA α , respectsEqTheory1A) i sort (varF x) = x
model1Eq→F→Q-algStr m1Eq@(algebra msetA α , respectsEqTheory1A) i sort (astF t) =
  α sort (mapTerm1 (model1Eq→F→Q-algStr m1Eq i) sort t)

model1Eq→Q→FEq : modelQ→FEq ∘ model1Eq→Q ≡ model1Eq→FEq
model1Eq→Q→FEq = funExt λ (m1Eq@(algebra msetA α , respectsEqTheory1A)) →
  Σ≡Prop isProp-respectsEqTheoryF (
    Σ≡Prop (λ _ → isPropIsEMAlgebra monadTermF) (cong₂ algebra
      refl
      (model1Eq→F→Q-algStr m1Eq)
    )
  )

ftrModel1Eq→Q→FEq : funcComp ftrModelQ→FEq ftrModel1Eq→Q ≡ ftrModel1Eq→FEq
ftrModel1Eq→Q→FEq = Functor≡
  (funExt⁻ model1Eq→Q→FEq)
  λ f → AlgebraHomPathP ftrTermF refl

{-# TERMINATING #-}
modelQ→1Eq→Q-algStr : (mA : Model)
  → model1Eq→Q-algStr (modelFEq→1Eq (modelQ→FEq mA))
   ≡ mA .fst .str
modelQ→1Eq→Q-algStr mA = foldModel-uniq2 (mA .fst .carrier) mA
  (algebraHom
    (model1Eq→Q-algStr (modelFEq→1Eq (modelQ→FEq mA)))
    ( model1Eq→Q-algStr-joinTermQ (modelFEq→1Eq (modelQ→FEq mA))
    ∙ funExt λ sort → cong (_∘ mapTermQ (model1Eq→Q-algStr (modelFEq→1Eq (modelQ→FEq mA))) sort)
      (funExt⁻ (modelQ→1Eq→Q-algStr mA) sort) -- induction
    )
  )
  (algebraHom
    (λ a → mA .fst .str a)
    (mA .snd .str-μ)
  )
  (sym (mA .snd .str-η))

modelQ→FEq→1Eq→Q : model1Eq→Q ∘ modelFEq→1Eq ∘ modelQ→FEq ≡ idfun Model
modelQ→FEq→1Eq→Q = funExt λ mA →
  Σ≡Prop (λ _ → isPropIsEMAlgebra monadTermQ) (cong₂ algebra
    refl
    (modelQ→1Eq→Q-algStr mA)
  )

ftrModelQ→FEq→1Eq→Q : funcComp (funcComp ftrModel1Eq→Q ftrModelFEq→1Eq) ftrModelQ→FEq ≡ funcId catModel
ftrModelQ→FEq→1Eq→Q = Functor≡
  (funExt⁻ modelQ→FEq→1Eq→Q)
  λ f → AlgebraHomPathP ftrTermQ refl

---------

isoftrModelFEq≅Q : P.PrecatIso (CatPrecategory ℓ-zero ℓ-zero) catModelFEq catModel
P≅.mor isoftrModelFEq≅Q = funcComp ftrModel1Eq→Q ftrModelFEq→1Eq
P≅.inv isoftrModelFEq≅Q = ftrModelQ→FEq
P≅.sec isoftrModelFEq≅Q = ftrModelQ→FEq→1Eq→Q
P≅.ret isoftrModelFEq≅Q =
  funcComp ftrModelQ→FEq (funcComp ftrModel1Eq→Q ftrModelFEq→1Eq)
    ≡⟨ F-assoc ⟩
  funcComp (funcComp ftrModelQ→FEq ftrModel1Eq→Q) ftrModelFEq→1Eq
    ≡⟨ cong (λ F → funcComp F ftrModelFEq→1Eq) ftrModel1Eq→Q→FEq ⟩
  funcComp ftrModel1Eq→FEq ftrModelFEq→1Eq
    ≡⟨ ftrModelFEq→1Eq→FEq ⟩
  funcId catModelFEq ∎

isoftrModel1Eq≅Q : P.PrecatIso (CatPrecategory ℓ-zero ℓ-zero) catModel1Eq catModel
P≅.mor isoftrModel1Eq≅Q = ftrModel1Eq→Q
P≅.inv isoftrModel1Eq≅Q = funcComp ftrModelFEq→1Eq ftrModelQ→FEq
P≅.sec isoftrModel1Eq≅Q =
  funcComp ftrModel1Eq→Q (funcComp ftrModelFEq→1Eq ftrModelQ→FEq)
    ≡⟨ F-assoc ⟩
  funcComp (funcComp ftrModel1Eq→Q ftrModelFEq→1Eq) ftrModelQ→FEq
    ≡⟨ ftrModelQ→FEq→1Eq→Q ⟩
  funcId catModel ∎
P≅.ret isoftrModel1Eq≅Q =
  funcComp (funcComp ftrModelFEq→1Eq ftrModelQ→FEq) ftrModel1Eq→Q
    ≡⟨ sym F-assoc ⟩
  funcComp ftrModelFEq→1Eq (funcComp ftrModelQ→FEq ftrModel1Eq→Q)
    ≡⟨ cong (funcComp ftrModelFEq→1Eq) ftrModel1Eq→Q→FEq ⟩
  funcComp ftrModelFEq→1Eq ftrModel1Eq→FEq
    ≡⟨ ftrModel1Eq→FEq→1Eq ⟩
  funcId catModel1Eq ∎

-----------

-- Syntax object
module _ where

  mSyntax : Model
  mSyntax = F-ob ftrFreeModel msetEmpty

  open NaturalBijection

  isInitial-mSyntax : isInitial catModel mSyntax
  isInitial-mSyntax = isLeftAdjoint→preservesInitial
    {C = catMSet}
    {D = catModel}
    ftrFreeModel
    (ftrForgetModel , emAdjunction monadTermQ)
    msetEmpty
    isInitial-msetEmpty

  
