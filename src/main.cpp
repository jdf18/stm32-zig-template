#include <stdint.h>

#ifdef NATIVE
    #include <stdio.h>
    #define NATIVE_DEBUG(func, ...) printf(#func "\n");
#else
    #include <libopencm3/stm32/rcc.h>
    #include <libopencm3/stm32/gpio.h>

    #define LED_PORT GPIOC
    #define RCC_LED_PORT RCC_GPIOC

    #define LED GPIO7

    #define NATIVE_DEBUG(func, ...) func(__VA_ARGS__);
#endif

void setup() {
    #ifdef NATIVE

    printf("Hello World!\n");

    #endif
}

int8_t loop() {
    return -1;
}

extern "C" int main() {

    #ifndef TEST
    setup();
    while (loop() != -1) {}
    #endif

    
    #ifdef TEST_blink

    NATIVE_DEBUG(rcc_periph_clock_enable, RCC_LED_PORT);
    
    NATIVE_DEBUG(gpio_mode_setup, LED_PORT, GPIO_MODE_OUTPUT, GPIO_PUPD_PULLUP, LED);
    NATIVE_DEBUG(gpio_set_output_options, LED_PORT, GPIO_OTYPE_PP, GPIO_OSPEED_MED, LED);
    
    // Flash led on and off
    while (true) {
        NATIVE_DEBUG(gpio_clear, LED_PORT, LED);
        for (int i = 0; i < 100000; i++) __asm__("nop");
        NATIVE_DEBUG(gpio_set, LED_PORT, LED);
        for (int i = 0; i < 100000; i++) __asm__("nop");
    }

    return 0;

    #endif
}

