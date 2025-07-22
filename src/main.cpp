#include <stdint.h>

#ifdef NATIVE
    #include <stdio.h>
#else
    #include <libopencm3/stm32/rcc.h>
    #include <libopencm3/stm32/gpio.h>

    #define LED_PORT GPIOC
    #define RCC_LED_PORT RCC_GPIOC

    #define LED GPIO7
#endif

extern "C" int main() {
    #ifdef NATIVE

    // Print hello world and exit
    printf("Hello World!\n");

    #else

    // Flash led on and off
    rcc_periph_clock_enable(RCC_LED_PORT);
    
    gpio_mode_setup(LED_PORT, GPIO_MODE_OUTPUT, GPIO_PUPD_PULLUP, LED);
    gpio_set_output_options(LED_PORT, GPIO_OTYPE_PP, GPIO_OSPEED_MED, LED);
    
    while (true) {
        gpio_clear(LED_PORT, LED);
        for (int i = 0; i < 100000; i++) __asm__("nop");
        gpio_set(LED_PORT, LED);
        for (int i = 0; i < 100000; i++) __asm__("nop");
    }

    #endif

    return 0;
}