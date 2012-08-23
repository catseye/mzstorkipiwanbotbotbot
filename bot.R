# Rtype -- an IRC bot written in R, the Language of the Future.
# Written by Chris Pressey of Cat's Eye Technologies.
# This work is hereby placed in the public domain.

# This bot's personality is modeled after that of a cat I knew once.
# Please forgive its inhospitable nature; it had a hard life.

args <- commandArgs(trailing=TRUE)
if (length(args) != 3) {
    cat("Usage: R ... --args botname irc.server.net '#channel'\n", file=stderr())
    quit(status=1)
}

bot <- args[1]
server <- args[2]
channel <- args[3]

hunt <- function(haystack, needle) {
    return(length(grep(needle, haystack, fixed=TRUE)) > 0)
}

irc <- socketConnection(host=server, port=6667, blocking=TRUE, open="a+b")

shove <- function(s) {
    cat(s,file=irc)
    cat(s,file=stderr())
}

action <- function(channel, s) {
    shove(paste("PRIVMSG", channel, ":\x01ACTION", s, "\x01\n"))
}

grab <- function() {
    line <- readLines(con=irc, n=1)
    cat(paste(">", line, "\n"), file=stderr())
    return(line)
}

state <- 0
done <- FALSE

while (!done) {
    line <- grab()
    if (length(line) == 0) { next }
    if (state == 0) {
        # I suppose this might only apply to certain servers.
        # (And to the case where you are not running ident.)
        loc <- hunt(line, "No Ident response")
        if (loc) {
            shove(paste("USER", bot, bot, bot, bot, "\n"))
            shove(paste("NICK", bot, "\n"))
            shove(paste("JOIN", channel, "\n"))
            state <- 1
        }
    }
    if (state == 1) {
        xform <- gsub('^:(.*?)\\!(.*?)\\s+PRIVMSG\\s+(.*?)\\s+\\:(.*?)$', '\\1\u2603\\2\u2603\\3\u2603\\4', line, perl=TRUE)
        if (length(xform) == 0) { next }
        if (xform != line) {
            parts <- strsplit(xform, '\u2603', fixed=TRUE)
            nick <- parts[[1]][1]
            in_channel <- parts[[1]][3]
            message <- parts[[1]][4]
            if (in_channel == channel & length(grep(bot, message, fixed=TRUE)) > 0) {
                choice = sample(1:4, 1)
                if (choice == 1) {
                    action(channel, paste("scowls at", nick))
                } else if (choice == 2) {
                    action(channel, paste("groans"))
                } else if (choice == 3) {
                    action(channel, paste("hisses"))
                } else if (choice == 4) {
                    shove(paste("PRIVMSG", channel, ":groan\n"))
                }
            }
        }
    }
    loc <- hunt(line, "PING")
    if (loc) {
        shove("PONG :irc.irc.irc\n")
    }
    if (!isOpen(irc)) {
        done <- TRUE
    }
}
