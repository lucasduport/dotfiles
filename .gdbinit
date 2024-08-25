tui new-layout debugasm {-horizontal asm 1 src 1} 2 cmd 1

define load-debugasm
  tui enable
  layout debugasm
  target remote localhost:1234
end
