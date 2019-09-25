# shell completion for seamore (jan.hegewald@awi.de)
# can be sourced from bash and zsh
# can not get this to pass through ksh without error, ksh can not parse the bash function definition: "ksh: .: syntax error: `(' unexpected"

if [ -n "$BASH_VERSION" ]; then
   # assume bash
   complete -F get_seamore_targets seamore
   function get_seamore_targets() {
      COMPREPLY=(`seamore help -c "${COMP_WORDS[@]:1}"`)
   }
elif [ -n "$ZSH_VERSION" ]; then
   # assume zsh
   autoload -U +X bashcompinit && bashcompinit
   # use the same as for bash for now (zsh is capable of much more, I know...)
   complete -F get_seamore_targets seamore
   function get_seamore_targets() {
      COMPREPLY=(`seamore help -c "${COMP_WORDS[@]:1}"`)
   }
fi
