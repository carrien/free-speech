function plot_params = get_plot_defaults()

plot_params = struct('hzbounds4plot', [0 5000], ...
    'figpos',get(0,'ScreenSize') + [50 100 -100 -200]); 