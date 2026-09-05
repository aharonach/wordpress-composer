<?php

defined( 'ABSPATH' ) || exit;

add_action('wp_enqueue_scripts', function () {
    wp_enqueue_style('custom-theme-style', get_stylesheet_uri());
});
