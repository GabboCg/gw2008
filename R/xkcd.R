# Theme XKCD
theme_xkcd <- theme(
  panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.75),
  panel.background = element_rect(fill = "white"), 
  axis.ticks.length = unit(0.125, "cm"),
  panel.grid = element_line(colour = "white"),
  axis.text.y = element_text(colour = "black"), 
  axis.text.x = element_text(colour = "black"),
  axis.line = element_line(colour = "black"),
  text = element_text(size = 16, family = "Humor Sans")
)