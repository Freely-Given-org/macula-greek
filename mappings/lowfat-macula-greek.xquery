(:
    Convert GBI trees to Lowfat format.

    NOTE: this should normally be used only by the MACULA team.  
    Lowfat is already available as part of the distribution.

:)

declare variable $retain-singletons := false();

declare function local:USFMBook($nodeId)
{
if(string-length($nodeId) < 1)
then "error5"
else
    switch (xs:integer(substring($nodeId, 1, 2)))
        case 01 return "GEN"
        case 02 return "EXO"
        case 03 return "LEV"
        case 04 return "NUM"
        case 05 return "DEU"
        case 06 return "JOS"
        case 07 return "JDG"
        case 08 return "RUT"
        case 09 return "1SA"
        case 10 return "2SA"
        case 11 return "1KI"
        case 12 return "2KI"
        case 13 return "1CH"
        case 14 return "2CH"
        case 15 return "EZR"
        case 16 return "NEH"
        case 17 return "EST"
        case 18 return "JOB"
        case 19 return "PSA"
        case 20 return "PRO"
        case 21 return "ECC"
        case 22 return "SNG"
        case 23 return "ISA"
        case 24 return "JER"
        case 25 return "LAM"
        case 26 return "EZK"
        case 27 return "DAN"
        case 28 return "HOS"
        case 29 return "JOL"
        case 30 return "AMO"
        case 31 return "OBA"
        case 32 return "JON"
        case 33 return "MIC"
        case 34 return "NAM"
        case 35 return "HAB"
        case 36 return "ZEP"
        case 37 return "HAG"
        case 38 return "ZEC"
        case 39 return "MAL"
        case 40 return "MAT"
        case 41 return "MRK"
        case 42 return "LUK"
        case 43 return "JHN"
        case 44 return "ACT"
        case 45 return "ROM"
        case 46 return "1CO"
        case 47 return "2CO"
        case 48 return "GAL"
        case 49 return "EPH"
        case 50 return "PHP"
        case 51 return "COL"
        case 52 return "1TH"
        case 53 return "2TH"
        case 54 return "1TI"
        case 55 return "2TI"
        case 56 return "TIT"
        case 57 return "PHM"
        case 58 return "HEB"
        case 59 return "JAS"
        case 60 return "1PE"
        case 61 return "2PE"
        case 62 return "1JN"
        case 63 return "2JN"
        case 64 return "3JN"
        case 65 return "JUD"
        case 66 return "REV"
        default return "###"
};

declare function local:head($node)
{
    if ($node)
    then
        let $preceding := count($node/preceding-sibling::Node)
        let $following := count($node/following-sibling::Node)
        return
            if ($preceding + $following > 0)
            then
                if ($preceding = $node/parent::*/@Head and $node/parent::*/@Cat != 'conj')
                then
                    attribute head {true()}
                else
                    ()
            else
                local:head($node/parent::*)
    else
        ()

};

declare function local:attributes($node)
{
    $node/@Cat ! attribute class {lower-case(.)},
    $node/@Type ! attribute type {lower-case(.)}[string-length(.) >= 1 and not(. = ("Logical", "Negative"))],
    $node/@xml:id,
    $node[empty(@xml:id)]/@nodeId ! local:nodeId2xmlId(.),
    $node/@HasDet ! attribute articular {true()},
    $node/@UnicodeLemma ! attribute lemma {.},
    $node/@NormalizedForm ! attribute normalized {.},
    $node/@StrongNumber ! attribute strong {.},
    $node/@Number ! attribute number {lower-case(.)},
    $node/@Person ! attribute person {lower-case(.)},
    $node/@Gender ! attribute gender {lower-case(.)},
    $node/@Case ! attribute case {lower-case(.)},
    $node/@Tense ! attribute tense {lower-case(.)},
    $node/@Voice ! attribute voice {lower-case(.)},
    $node/@Mood ! attribute mood {lower-case(.)},
    $node/@Degree ! attribute degree {lower-case(.)},
    local:head($node),
    $node[empty(*)] ! attribute discontinuous {"true"}[$node/following::Node[empty(*)][1]/@morphId lt $node/@morphId],
    $node/@Rule ! attribute rule {.},
    $node/@Gloss ! attribute gloss {.},
    $node/@LexDomain ! attribute domain {.},
    $node/@LN ! attribute ln {.},
    $node/@FunctionalTag ! attribute morph {.},
    $node/@Unicode ! attribute unicode {.},
    $node/@Frame ! attribute frame {.},
    $node/@Ref ! attribute referent {.},
    $node/@SubjRef  ! attribute subjref {.},
    $node/@ClType ! attribute cltype {.}  (:  ### Remove later - for debugging purposes #### :)
};


(: TODO: the USFM id does not need to be computed from the Nodes trees, since USFM ids are now included on verses and words :)
declare function local:USFMId($nodeId)
{
if(string-length($nodeId) < 1) 
then "error6NoIDFoundInNode"
else
    concat(local:USFMBook($nodeId),
    " ",
    xs:integer(substring($nodeId, 3, 3)),
    ":",
    xs:integer(substring($nodeId, 6, 3)),
    "!",
    xs:integer(substring($nodeId, 9, 3))
    )
};


declare function local:USFMVerseId($nodeId)
{
if(string-length($nodeId) < 1) 
then "error7"
else
    concat(local:USFMBook($nodeId),
    " ",
    xs:integer(substring($nodeId, 3, 3)),
    ":",
    xs:integer(substring($nodeId, 6, 3))
    )
};

declare function local:nodeId2xmlId($nodeId)
{
   attribute xml:id { concat("n", $nodeId) }
};

declare function local:is-peripheral($node)
{
    $node/@ClType="Minor"
    or
    $node/*[@Cat="V"]/descendant::Node[@LN="91.13"]
    (:    Prompters of Attention
        ἄγε     look	91.13
        ἴδε     look!	91.13
        ἰδού    a look!        91.13
        
        
        In theory, the above condition is too general, but applying the following path to the result
        shows that it did not result in false positives:
        
        //comment()[ contains(string(.), "91.3") and count(following-sibling::*[1]/descendant::w) ne 1]
        => empty
        
        //comment()[ contains(string(.), "91.3") and count(following-sibling::*[1]/descendant::w) eq 1]
        => 157 items
    :)
};

declare function local:is-adjunct-cl($node)
{
    $node/@Rule = "sub-CL"
    or
    (
        $node/parent::Node[@Cat="CL" and @Rule=("ClCl","ClCl2")]
        and
        $node/Node[@Cat=("V","VC")]
        /Node[@Cat="vp"]
        /Node[@Cat="verb" and @Mood="Participle" 
        and 
        @Case=("Genitive", "Accusative","Dative")]
    )
};

declare function local:is-adjunct-wg($node)
{
    $node/@Rule=("PtclCL", "AdvpCL", "Conj-CL") 
    and 
    $node/parent::*/@Rule=("ClCl", "ClCl2")
};

declare function local:is-object-thatVP($node)
{
    $node/@Rule=("that-VP")
};

(: Most confident of EitherOr4CL, EitherOr7CL, aCLaCL, aCLaCLaCL:)
declare variable $group-rules := ("CLaCL","CLa2CL", "2CLaCL", "2CLaCLaCL", 
    "Conj12CL", "Conj13CL", "Conj14CL", "Conj3CL", "Conj4CL", "Conj5CL", "Conj6CL",
    "Conj7CL", "CLandClClandClandClandCl", "EitherOr4CL", "EitherOr7CL","aCLaCL", "aCLaCLaCL", "notCLbutCL2CL" );

declare function local:is-group($node)
{
    starts-with($node/@Rule, "ClClCl") or $node/@Rule = $group-rules
};


declare function local:raise-sibling($parent-node, $child-node-to-raise)
{
    <wg>
     {
        let $processed-node-to-raise := local:node($child-node-to-raise)
        let $before := $parent-node/*[. << $child-node-to-raise]
        let $after := $parent-node/*[. >> $child-node-to-raise]
        return (
            (:  A ClCl or ClCl2 always has @Cat="CL", so it will never have a role. If the raised hcild has a role, use it. :)
            $processed-node-to-raise/@*,
            comment{ $parent-node/@Rule, $child-node-to-raise/@Rule, count($parent-node/*[.<<$child-node-to-raise]) +1  },
            $before ! local:node(.),
            $processed-node-to-raise/node(),
            $after ! local:node(.)
        )
     }
    </wg>
};

declare function local:keep-siblings-as-siblings($node)
{
    <wg>
      {
        $node/@nodeId ! local:nodeId2xmlId(.),
        $node/@Rule ! attribute rule { lower-case(.) },           
        $node/Node ! local:node(.)
     }           
    </wg>
};

declare function local:clause($node)
(:  
   See https://github.com/Clear-Bible/symphony-team/issues/91  
:)
{
    if ( $node=>local:is-peripheral() ) then
        <wg role="aux" class="minor">
         {
            local:attributes($node)[not(name(.) = ("role","class"))], 
            $node/Node ! local:node(.)
         }
        </wg>
          
    else if ( $node=>local:is-adjunct-wg() ) then
        <wg role="adv" class="wg">
          {
                local:attributes($node)[not(name(.) = ("role","class"))],
                $node/Node ! local:node(.)         
           }     
        </wg>
        
    else if ( $node=>local:is-adjunct-cl() ) then
        <wg role="adv" class="cl">
          {
                local:attributes($node)[not(name(.) = ("role","class"))],
                $node/Node ! local:node(.)         
           }     
        </wg>         
        
     else if ( $node =>local:is-object-thatVP() ) then 
          <wg role="o" class="wg"> 
            {
                local:attributes($node)[not(name(.) = ("role", "class"))],
                $node/Node ! local:node(.)         
           }     
          </wg> 

     else if ($node/@Rule=("Conj-CL")) then
         <wg class="wg">
           {
                local:attributes($node)[not(name(.) = ("class"))],
                $node/Node ! local:node(.)         
            }
          </wg>

else if (starts-with($node/@Rule, "ClClCl") or $node/@Rule = $group-rules ) then
          (: ### TODO:  Handle groups of groups :)
        <wg role="g" class="group">
         {
            $node/@nodeId ! local:nodeId2xmlId(.),
            $node/@Rule ! attribute rule { lower-case(.) },
            $node/Node ! local:node(.)
         }
        </wg>    
        
    else if (
            some $child in $node/* satisfies (
                $child => local:is-peripheral()
                or
                $child => local:is-adjunct-wg() 
                or
                $child => local:is-adjunct-cl() 
                or
                $child =>local:is-object-thatVP())
            and
                $node/@Rule="ClCl"
    ) 
        then local:raise-sibling($node, $node/*[1])
    else if ( $node/@Rule="ClCl" )
        then
         <wg class="wg">
           {
                local:attributes($node)[not(name(.) = ("class"))],
                comment { "Flat ClCl" },
                $node/Node ! local:node(.)         
            }
          </wg>        

    else if ($node/@Rule="ClCl2") then
        local:raise-sibling($node, $node/*[2])

    else
        <wg>
         {
            local:attributes($node),
            comment { "local:clause(), else" },
            $node/Node ! local:node(.)
         }
        </wg>
};


(:  
    The "singleton phrases" rules have these things in common:
    
    1. They always have a single child that represents a word
    2. They never live in elements that represent clauses
    3. Their descendants are singletons at each level
    4. The @Cat attribute is one of the following, and does not represent a role:
    
        adj
        adjp
        adv
        advp
        conj
        intj
        np
        nump
        prep
        pron
        ptcl
        vp
:)

declare variable $singleton-phrases := (
      "Adj2Adjp","Adj2Advp","Adv2Adj","Adv2Advp", "Adv2Conj", "Adv2Prep", "Adv2Ptcl", 
      "Conj2Adv", "Conj2Prep", "Conj2Pron", "Conj2Ptcl", "Det2NP", "N2NP", "Num2Nump", 
      "Prep2Adv", "Pron2NP", "Ptcl2Adv", "Ptcl2Conj", "Ptcl2Intj", "Ptcl2Np", "V2VP", "intj2Np","pron2adj"
 );
 
 declare function local:singleton($node)
 {
    <singleton>{ 
        $node/descendant::Node[empty(Node)] ! local:node(.)    
    }</singleton>
 };

declare function local:phrase($node)
{
(:
     #### BUG - I might have various levels of children at this point.  Still not out of the water. #####
     #### BUG - roles with participles, infinitiives  (v.part, v.inf)


    if ($node/@Rule=$singleton-phrases and count($node/descendant::Node[empty(Node)]) eq 1)
    then local:singleton($node)
    else
:)
        <wg>
            {
                local:attributes($node),
                $node/Node ! local:node(.)
            }
        </wg>
};

declare function local:role($node)
{
    let $role := attribute role {lower-case($node/@Cat)}
    return
        if (count($node/Node) > 1)
        then
            <wg>
                {
                    $role,
                    $node/@nodeId ! local:nodeId2xmlId(.),
                    comment { "Role created from ", $node/@Rule },
                    $node/Node ! local:node(.)
                }
            </wg>
        else
            element {if ($node/Node/Node) then "wg" else "w"}
                {
                    let $child := local:node($node/Node)
                    return (
                        $role,
                        $child/@* except $child/@role,
                        comment { "Role created from ", $node/@Rule },
                        $child/node()
                    )
                }
};

declare function local:word($node)
{
    local:word($node, ())
};

declare function local:word($node, $role)
(: $role can contain a role attribute or a null sequence :)
{
    let $wordContent := $node/text()
    let $wordContentWithoutBrackets := replace($node/text(), '([\(\)\[\]])', '') 
    let $normalizedFormWordLength := string-length($node/@NormalizedForm)
    let $normalizedFormWithPunctuationLength := $normalizedFormWordLength + 1
    return
        if ($node/*)
        then
            (element error {$role, $node})
        else
            if (string-length($wordContentWithoutBrackets) = $normalizedFormWithPunctuationLength)
            then
                (: place punctuation in an 'after' attribute :)
                <w>
                    {
                        $role,
                        attribute ref {local:USFMId($node/@nodeId)},
                        attribute after {substring($wordContentWithoutBrackets, string-length($wordContentWithoutBrackets), 1)},
                        local:attributes($node),
                        substring($wordContentWithoutBrackets, 1, string-length($wordContentWithoutBrackets) - 1)
                    }
                </w>
            else
                <w>
                    {
                        $role,
                        attribute ref {local:USFMId($node/@nodeId)},
                        attribute after {' '},
                        local:attributes($node),
                        string($wordContentWithoutBrackets)
                    }
                </w>
};

declare function local:node-type($node as element(Node))
{
    if ($node/@UnicodeLemma)
    then
        "word"
    else
        switch ($node/@Cat)
            case "adj"
            case "adv"
            case "conj"
            case "det"
            case "noun"
            case "num"
            case "prep"
            case "ptcl"
            case "pron"
            case "verb"
            case "intj"
            case "adjp"
            case "advp"
            case "np"
            case "nump"
            case "pp"
            case "vp"
                return
                    "phrase"
            case "S"
            case "IO"
            case "ADV"
            case "O"
            case "O2"
            case "P"
            case "V"
            case "VC"
                return
                    "role"
            case "CL"
                return
                    "clause"
            default
            return
                "####"
};

declare function local:node($node as element(Node))
{
    switch (local:node-type($node))
        case "word"
            return
                local:word($node)
        case "phrase"
            return
                local:phrase($node)
        case "role"
            return
                local:role($node)
        case "clause"
            return
                local:clause($node)
        default
        return
            $node
};

declare function local:straight-text($node)
{
    for $n at $i in $node//Node[local:node-type(.) = 'word']
        order by $n/@morphId
    return
        string($n/@Unicode)
};

declare function local:sentence($node)
{
    <sentence>
        {
            <p>
                {
                    for $verse in distinct-values($node//Node/@nodeId ! local:USFMVerseId(.))
                    return
                        (
                        <milestone
                            unit="verse">
                            {attribute id {$verse}, $verse}
                        </milestone>
                        ,
                        " "
                        )
                }
                {local:straight-text($node)}
            </p>,
            
            if (count($node/Node) > 1 or not($node/Node/@node = 'CL'))
            then
                <wg>{$node/Node ! local:node(.)}</wg>
            else
                local:node($node/Node)
            
        }
    </sentence>
};

processing-instruction xml-stylesheet {'href="treedown.css"'},
processing-instruction xml-stylesheet {'href="boxwood.css"'},
<book>
    {
        attribute id {local:USFMBook((//Node)[1]/@nodeId)},
        (:
            If a sentence has multiple interpretations, Sentence/Trees may contain
            multiple Tree nodes.  We want only the first.
        :)
        for $sentence in //Tree[1]/Node
        return
            local:sentence($sentence)
    }
</book>