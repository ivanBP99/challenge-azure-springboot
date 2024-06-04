package com.example.app.controller;

import com.example.app.entity.Person;
import com.example.app.services.PersonServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;
import java.util.Optional;

@RestController
public class PersonController {

    @Autowired
    private PersonServiceImpl personService;

    @PostMapping("/createperson")
    public ResponseEntity<Object> create(@Valid @RequestBody Person person) {
        personService.guardar(person);
        return new ResponseEntity<>("El usuario fue creado!", HttpStatus.CREATED);
    }

    @GetMapping("/getpersons")
    public ResponseEntity<List<Person>> getAllPersons() {
        List<Person> persons = personService.getAllPersons();
        return new ResponseEntity<>(persons, HttpStatus.OK);
    }

    @PutMapping("/updateperson/{id}")
    public <person> ResponseEntity<String> updatePerson(@Valid @PathVariable Long id, @RequestBody Person updatedPerson) {
        System.out.println("que valor es ? " + id);
        try {
            System.out.println("que valor es ? " + id);
            Optional<Person> existingPerson = personService.getPersonById(id);
            if (existingPerson.isPresent()) {

                existingPerson.get().setName(updatedPerson.getName());
                existingPerson.get().setAddress(updatedPerson.getAddress());
                existingPerson.get().setPhone(updatedPerson.getPhone());
                personService.guardar(existingPerson.get());
                return new ResponseEntity<>("El usuario con ID " + id + " fue actualizado.", HttpStatus.OK);
            } else {
                return new ResponseEntity<>("No hay ningún usuario con el ID " + id, HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            // Manejar otros errores aquí (por ejemplo, validaciones fallidas)
            return new ResponseEntity<>("Error al actualizar el usuario con ID " + id, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @DeleteMapping("/deleteperson/{id}")
    public ResponseEntity<String> deletePerson(@Valid @PathVariable Long id) {
        personService.eliminar(id);
        return new ResponseEntity<>("El usuario con ID " + id + " fue eliminado.", HttpStatus.OK);
    }
}
