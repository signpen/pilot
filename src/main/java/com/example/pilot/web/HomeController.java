package com.example.pilot.web;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping({"/", "/home"})
    public String home(Model model) {
        model.addAttribute("title", "Pilot Spring MVC Sample");
        model.addAttribute("message", "GitHub workflow verification용 샘플 Spring MVC 프로젝트입니다.");
        model.addAttribute("javaVersion", System.getProperty("java.version"));
        return "home";
    }
}
