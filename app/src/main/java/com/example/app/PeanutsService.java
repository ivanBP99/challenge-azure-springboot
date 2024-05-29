package com.example.app;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class PeanutsService {
    @Autowired
    private PeanutsRepository repository;

    public Peanuts getPeanutsById(Long id) {
        return repository.findById(id).orElse(null);
    }

    public Peanuts savePeanuts(Peanuts peanuts) {
        return repository.save(peanuts);
    }
}
