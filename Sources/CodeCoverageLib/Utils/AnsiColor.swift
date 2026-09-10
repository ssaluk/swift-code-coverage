import Foundation

public enum AnsiColor: String {
    case blackText   = "\u{001B}[0;30m",
         redText     = "\u{001B}[0;31m",
         greenText   = "\u{001B}[0;32m",
         yellowText  = "\u{001B}[0;33m",
         blueText    = "\u{001B}[0;34m",
         magentaText = "\u{001B}[0;35m",
         cyanText    = "\u{001B}[0;36m",
         whiteText   = "\u{001B}[0;37m",

         backgroundBlack   = "\u{001B}[0;40m",
         backgroundRed     = "\u{001B}[0;41m",
         backgroundGreen   = "\u{001B}[0;42m",
         backgroundYellow  = "\u{001B}[0;43m",
         backgroundBlue    = "\u{001B}[0;44m",
         backgroundMagenta = "\u{001B}[0;45m",
         backgroundCyan    = "\u{001B}[0;46m",
         backgroundWhite   = "\u{001B}[0;47m",

         reset = "\u{001B}[0;0m"
}

extension String {
    func color(text: AnsiColor, background: AnsiColor) -> String {
        "\(text.rawValue)\(background.rawValue)\(self)\(AnsiColor.reset.rawValue)"
    }

    func color(_ ansiColor: AnsiColor) -> String {
        "\(ansiColor.rawValue)\(self)\(AnsiColor.reset.rawValue)"
    }
}
