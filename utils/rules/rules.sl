import org.dashnine.preditor.* from: lib/spellutils.jar;
use(^SpellingUtils);

if (getFileName($__SCRIPT__) eq 'rules.sl')
{
   # misc junk
   include("lib/dictionary.sl");
   global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $account $usage $endings $lexdb $trigrams $verbs');
   $model      = get_language_model();
   $dictionary = dictionary();
   $dsize      = size($dictionary);
}
include("lib/fsm.sl");

#
# create our FSM rule engine.
#
global('$rules $homophones $agreement $voice $rcount');
$rules      = machine();
$homophones = machine();
$agreement  = machine();
$voice      = machine();

#
# load rules in general from a rules file (this thing handles POS tags as well)
#
# <rule file> format:
#
# rule..|[key=value|...]
#
# note that key=value are parsed and dumped into a hash.  This information is used by the system to
# filter out false positives and stuff.
#
# loadRules($rules, "filename", %(default hash))
sub loadRules
{
   local('$handle $text $rule %r @r $v $key $value $option');

   $handle = openf($2);
   while $text (readln($handle))
   {
      if ($text ne "" && "#*" !iswm $text)
      {
         $rule = split('\:\:', $text)[0];
         %r    = copy($3);

         foreach $v (sublist(split('\:\:', $text), 1))
         {
            ($key, $value) = split('=', $v);
            %r[$key] = $value;
         }

         @r = split(' ', $rule);
         @r = map(
         {
            if ('*/*' iswm $1)
            {
               return split('/', $1);
            }
            else if ('&*' iswm $1)
            {
               return @(invoke($1), '.*');
            }
            return @($1, '.*');
         }, @r);

         if (@r[0][0] eq "")
         {
             addPath($1, %r, @r);
         }
         else if ('|' isin @r[0][0])
         {
            foreach $option (split('\|', @r[0][0]))
            {
               addPath($1, %r, concat(@(@($option, @r[0][1])), sublist(@r, 1)));
            }
         }
         else
         {
            addPath($1, %r, @r);
         }
      }
   }

   return $1;
}



#
# bias rules (non-discrimination, gender neutral language)
#

sub bias
{
   return %(recommendation => { return " $2 "; },
            view => "view/rules/bias.slp",
            rule => "Faire Sprache",
            description => "Das kann faire Sprache: Sprache verstärkt häufig Stereotype, zum Beispiel solche die Geschlechter betreffen. Mit fairer Sprache bringst du allen Menschen Respekt entgegen - unabhängig von ihrem Geschlecht und anderen Identitäten und Positionen in der Gesellschaft.",
            style => 'unfair',
            word => $1,
            category => 'Bias');
}

sub loadBiasRules
{
   local('$handle $text $expression $suggestion');

   $handle = openf("data/rules/biasdb.txt");
   while $text (readln($handle))
   {
      ($expression, $suggestion) = split('\t+', $text);
#      println("$[30]expression ... $suggestion");
      [$expression trim];
      [$suggestion trim];
      addPath($rules, bias($suggestion), split('\s+', $expression));
   }
}



#
# load the rules
#

if (getFileName($__SCRIPT__) eq "rules.sl")
{
   loadBiasRules();

   $rcount = countRules($rules) + countRules($homophones) + countRules($agreement) + countRules($voice);
   $rcount = substr($rcount, 0, -3) . ',' . right($rcount, 3);

   [{
      local('$handle');

      $handle = openf(">models/rules.bin");
      writeObject($handle, $rcount);

      writeObject($handle, $homophones);
      writeObject($handle, $rules);
      writeObject($handle, $agreement);
      writeObject($handle, $voice);

      closef($handle);
   }];

   println("--- Normal rules:    " . countRules($rules));
   println("--- Homophone rules: " . countRules($homophones));
   println("--- Agreement rules: " . countRules($agreement));
   println("--- Voice  rules:    " . countRules($voice));
   println("Loaded $rcount rules... wheee");
}
