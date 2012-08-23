mzstorkipiwanbotbotbot
======================

This repository actually contains two implementations of two different bots
written in two different languages.  The ongoing idea is that they should be
merged into a single bot, called mzstorkipiwanbotbotbot, written in R.  This
will never happen.

_mzstorkipiwanbotbotbot_ is an IRC bot with no purpose or plan.  It supports
a small command language (parsed using Lua patterns — clearly the best way to
parse anything) in which variables can be defined with nick, server, or
channel scope.  It requires [ncat][] or some similar tool to connect to IRC.

_Rtype_ is an IRC bot with a difference — it's written in R, the Language of
the Future. Also features extensive use of Unicode snowmen → ☃☃☃

Rtype does not require anything extra to connect to IRC.  But it also doesn't
do nearly as much as mzstorkipiwanbotbotbot does.  But there is some potential
for a bot written in R to save its state as an R workspace, and thus remember
all the nick/server/channel variables between settings.

The source code for both of these bots is in the public domain.

[ncat]: http://nmap.org/ncat/
